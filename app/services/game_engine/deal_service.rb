module GameEngine
  # Distributes cards to players and sets initial game state
  class DealService
    def initialize(match, player_ids)
      @match      = match
      @player_ids = player_ids
    end

    def call
      deck = GameEngine::DeckService.build_and_shuffle
      hands = distribute(deck)

      # Find who has Ace of Spades — they go first
      first_player_id = hands.find { |pid, cards| cards.any? { |c| c[:code] == "AS" } }&.first

      # Build initial game state
      initial_state = {
        "hands"             => hands.transform_values { |cards| cards.map { |c| c[:code] } },
        "current_turn"      => first_player_id,
        "trick_leader"      => first_player_id,
        "leading_suit"      => nil,
        "trick_pile"        => [],        # [{player_id: X, card: "AS"}, ...]
        "active_players"    => @player_ids.map(&:to_s),
        "finished_players"  => [],
        "move_seq"          => 0,
        "current_trick"     => 1,
        "current_round"     => 1,
        "safe_exit_rank"    => 1         # rank counter for safe exits
      }

      @match.update!(
        game_state: initial_state,
        started_at: Time.current
      )

      # Send each player their private hand via ActionCable
      hands.each do |player_id, cards|
        ActionCable.server.broadcast(
          "game_#{@match.id}_player_#{player_id}",
          {
            type: "deal_cards",
            data: {
              hand:           cards.map { |c| c[:code] },
              card_count:     cards.size,
              total_players:  @player_ids.size
            }
          }
        )
      end

      # Announce who goes first
      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "game_started",
        data: {
          first_player_id: first_player_id,
          player_order:    @player_ids,
          total_cards:     52,
          cards_per_player: deck.size / @player_ids.size
        }
      })

      # Notify current player it's their turn
      notify_turn(first_player_id.to_i)

      # Schedule move timeout for first player
      schedule_timeout(first_player_id.to_i)

      true
    end

    private

    def distribute(deck)
      hands = @player_ids.map { |pid| [pid.to_s, []] }.to_h
      deck.each_with_index do |card, i|
        player_id = @player_ids[i % @player_ids.size].to_s
        hands[player_id] << card
      end
      hands
    end

    def notify_turn(player_id)
      ActionCable.server.broadcast(
        "game_#{@match.id}_player_#{player_id}",
        {
          type: "your_turn",
          data: {
            match_id:        @match.id,
            leading_suit:    nil,
            trick_pile:      [],
            timeout_seconds: @match.game_room.move_timeout
          }
        }
      )
    end

    def schedule_timeout(player_id)
      timeout = @match.game_room.move_timeout
      GameMoveTimeoutJob.set(wait: timeout.seconds).perform_later(
        @match.id,
        player_id,
        0 # move_seq at start
      )
    end
  end
end
