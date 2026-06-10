module GameEngine
  # Auto-plays the lowest legal card when a player times out
  class AutoPlayService
    def initialize(match:, player_id:, move_seq:)
      @match     = match
      @player_id = player_id.to_s
      @move_seq  = move_seq
      @state     = match.game_state
    end

    def call
      # Verify it's still this player's turn and move_seq matches
      return false unless @state["current_turn"].to_s == @player_id
      return false unless @state["move_seq"].to_i == @move_seq.to_i

      card = select_card
      return false unless card

      # Notify channel that this was auto-played
      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "move_timeout",
        data: {
          player_id:   @player_id,
          auto_played: true,
          card:        card,
          timeout_seconds: @match.game_room.move_timeout
        }
      })

      # Execute the move as if the player played it
      GameEngine::TurnManager.new(
        match:     @match,
        player_id: @player_id,
        card_code: card,
        move_seq:  @move_seq
      ).execute!

      # Overwrite move_type in the DB record to auto_play
      @match.game_moves.where(player_id: @player_id.to_i, move_seq: @state["move_seq"].to_i)
            .update_all(move_type: "auto_play")

      true
    rescue => e
      Rails.logger.error "[AutoPlayService] Error: #{e.message}"
      false
    end

    private

    def select_card
      hand         = @state.dig("hands", @player_id) || []
      leading_suit = @state["leading_suit"]

      return hand.first if leading_suit.nil?

      # Prefer lowest leading-suit card (to avoid wasting high cards)
      suit_cards = hand.select { |c| GameEngine::DeckService.card_suit(c) == leading_suit }
      if suit_cards.any?
        return suit_cards.min_by { |c| GameEngine::DeckService.card_value(c) }
      end

      # No leading suit — play lowest card (valid cut)
      hand.min_by { |c| GameEngine::DeckService.card_value(c) }
    end
  end
end
