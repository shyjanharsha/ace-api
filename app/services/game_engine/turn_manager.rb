module GameEngine
  # Handles a player playing a card:
  # 1. Validates the move
  # 2. Updates game state
  # 3. Broadcasts to channels
  # 4. Resolves trick if all active players have played
  # 5. Detects safe exits and donkey
  class TurnManager
    def initialize(match:, player_id:, card_code:, move_seq: nil)
      @match      = match
      @player_id  = player_id.to_s
      @card_code  = card_code.upcase
      @move_seq   = move_seq
      @state      = match.game_state
    end

    def execute!
      # Validate the move
      validator = GameEngine::MoveValidator.new(
        match: @match, player_id: @player_id,
        card_code: @card_code, move_seq: @move_seq
      )
      unless validator.valid?
        raise Errors::InvalidMove, validator.error_message
      end

      ActiveRecord::Base.transaction do
        # Remove card from hand
        hand = @state.dig("hands", @player_id)
        hand.delete(@card_code)
        @state["hands"][@player_id] = hand

        # Determine if this is a cut
        leading_suit  = @state["leading_suit"]
        played_suit   = GameEngine::DeckService.card_suit(@card_code)
        is_cut        = leading_suit.present? && played_suit != leading_suit

        # Set leading suit if first card of trick
        @state["leading_suit"] ||= played_suit

        # Add to trick pile
        @state["trick_pile"] << { "player_id" => @player_id, "card" => @card_code }

        # Increment move sequence
        @state["move_seq"] = @state["move_seq"].to_i + 1

        # Save game state
        @match.update!(game_state: @state)

        # Save move to DB for replay + analytics
        move_record = save_move!(is_cut)

        # Append to replay log
        @match.append_to_replay!({
          seq:       @state["move_seq"],
          player_id: @player_id,
          card:      @card_code,
          trick:     @state["current_trick"],
          is_cut:    is_cut,
          ts:        Time.current.iso8601
        })

        # Broadcast the played card to all
        ActionCable.server.broadcast("game_#{@match.id}", {
          type: "card_played",
          data: {
            player_id:   @player_id,
            card:        @card_code,
            is_cut:      is_cut,
            trick_pile:  @state["trick_pile"],
            move_seq:    @state["move_seq"]
          }
        })

        # Check if all active players have played this trick
        active_count  = @state["active_players"].size
        trick_count   = @state["trick_pile"].size

        if trick_count >= active_count
          # Resolve the trick
          resolve_trick!(move_record)
        else
          # Advance turn to next player
          advance_turn!
        end
      end
    end

    private

    def save_move!(is_cut)
      @match.game_moves.create!(
        player_id:    @player_id.to_i,
        round_number: @state["current_round"].to_i,
        trick_number: @state["current_trick"].to_i,
        move_seq:     @state["move_seq"].to_i,
        card_played:  @card_code,
        move_type:    "play",
        is_cut:       is_cut,
        played_at:    Time.current
      )
    end

    def resolve_trick!(move_record)
      result = GameEngine::TrickResolver.new(@match).resolve
      next_leader_id = result[:next_leader_id].to_s

      # Update trick winner stats
      move_record.update!(won_trick: result[:winner_id].to_s == @player_id)
      mp = @match.match_players.find_by(user_id: result[:winner_id])
      mp&.increment!(:tricks_won)

      # Broadcast trick result
      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "trick_complete",
        data: {
          winner_id:       result[:winner_id],
          collected_cards: result[:collected_cards],
          was_cut:         result[:was_cut],
          cutter_id:       result[:cutter_id],
          next_leader_id:  next_leader_id,
          trick_number:    @state["current_trick"]
        }
      })

      # Check for safe exits — players who have run out of cards
      check_safe_exits!

      # Check if game is over (only 1 player left)
      if @state["active_players"].size <= 1
        declare_donkey!
        return
      end

      # Reset for next trick
      @state["trick_pile"]  = []
      @state["leading_suit"] = nil
      @state["current_trick"] = @state["current_trick"].to_i + 1
      @state["current_turn"] = next_leader_id
      @state["trick_leader"] = next_leader_id
      @match.update!(game_state: @state)

      # Notify next player
      notify_turn!(next_leader_id.to_i)
      schedule_timeout!(next_leader_id.to_i)
    end

    def advance_turn!
      # Find next player in active_players after current player
      active   = @state["active_players"]
      idx      = active.index(@player_id)
      next_pid = active[(idx + 1) % active.size]

      @state["current_turn"] = next_pid
      @match.update!(game_state: @state)

      notify_turn!(next_pid.to_i)
      schedule_timeout!(next_pid.to_i)
    end

    def check_safe_exits!
      newly_finished = []

      @state["active_players"].dup.each do |pid|
        hand = @state.dig("hands", pid) || []
        if hand.empty?
          rank = @state["safe_exit_rank"].to_i
          @state["active_players"].delete(pid)
          @state["finished_players"] << pid
          @state["safe_exit_rank"] = rank + 1

          mp = @match.match_players.find_by(user_id: pid.to_i)
          mp&.mark_finished!(rank)

          newly_finished << { user_id: pid, rank: rank }
        end
      end

      return if newly_finished.empty?

      @match.update!(game_state: @state)

      newly_finished.each do |exit_info|
        ActionCable.server.broadcast("game_#{@match.id}", {
          type: "player_finished",
          data: exit_info
        })
      end
    end

    def declare_donkey!
      donkey_id = @state["active_players"].first
      mp = @match.match_players.find_by(user_id: donkey_id.to_i)
      mp&.mark_donkey!

      @match.complete!(User.find(donkey_id.to_i))

      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "game_over",
        data: {
          donkey_id:    donkey_id,
          donkey_name:  User.find(donkey_id.to_i).username,
          match_id:     @match.id,
          final_ranks:  @match.match_players.order(:final_rank).map { |mp|
            { user_id: mp.user_id, rank: mp.final_rank, is_donkey: mp.is_donkey }
          }
        }
      })

      # Trigger async analytics + coin distribution
      MatchAnalyticsJob.perform_later(@match.id)

      # Update room status
      @match.game_room.update!(status: "finished")
    end

    def notify_turn!(player_id)
      ActionCable.server.broadcast(
        "game_#{@match.id}_player_#{player_id}",
        {
          type: "your_turn",
          data: {
            match_id:        @match.id,
            leading_suit:    @match.game_state["leading_suit"],
            trick_pile:      @match.game_state["trick_pile"],
            timeout_seconds: @match.game_room.move_timeout,
            move_seq:        @match.game_state["move_seq"]
          }
        }
      )
    end

    def schedule_timeout!(player_id)
      timeout = @match.game_room.move_timeout
      GameMoveTimeoutJob.set(wait: timeout.seconds).perform_later(
        @match.id,
        player_id,
        @match.game_state["move_seq"]
      )
    end
  end
end
