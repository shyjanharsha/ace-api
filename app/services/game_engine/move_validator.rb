module GameEngine
  # Validates whether a player's move is legal.
  # Cut rule: optional — player CAN cut (play off-suit) only if they
  # have NO card of the leading suit. If they DO have a leading suit card,
  # they MUST play it (server validates and rejects off-suit).
  class MoveValidator
    attr_reader :error_message

    def initialize(match:, player_id:, card_code:, move_seq: nil)
      @match      = match
      @player_id  = player_id.to_s
      @card_code  = card_code.upcase
      @move_seq   = move_seq
      @state      = match.game_state
      @error      = nil
    end

    def valid?
      validate_turn    &&
      validate_card_in_hand &&
      validate_suit_rule &&
      validate_move_seq
      @error.nil?
    end

    def error_message
      @error
    end

    private

    # Rule 1: Is it this player's turn?
    def validate_turn
      unless @state["current_turn"].to_s == @player_id
        @error = "It's not your turn"
        return false
      end
      true
    end

    # Rule 2: Does the player actually hold this card?
    def validate_card_in_hand
      hand = @state.dig("hands", @player_id) || []
      unless hand.include?(@card_code)
        @error = "You don't have that card (anti-cheat: card not in hand)"
        return false
      end
      true
    end

    # Rule 3: Suit following rule
    # - If there IS a leading suit for this trick, player MUST play it if they have one
    # - Playing off-suit is only allowed if player has NO leading suit card (constitutes a cut)
    # - Cut is "optional" in the sense the player chooses WHICH non-leading card to play,
    #   but it's only legal at all when they lack the leading suit
    def validate_suit_rule
      leading_suit = @state["leading_suit"]
      return true if leading_suit.nil?  # No leading suit yet (trick just started) — any card fine

      played_suit = GameEngine::DeckService.card_suit(@card_code)

      # Player is playing the correct suit — always legal
      return true if played_suit == leading_suit

      # Player is playing off-suit — only legal if they have NO leading suit card
      hand = @state.dig("hands", @player_id) || []
      has_leading_suit = hand.any? do |code|
        GameEngine::DeckService.card_suit(code) == leading_suit
      end

      if has_leading_suit
        @error = "You must follow suit (#{leading_suit}). You have a #{leading_suit} card."
        return false
      end

      # Valid cut — player has no leading suit card
      true
    end

    # Rule 4: Sequence check (anti-replay attack)
    def validate_move_seq
      return true if @move_seq.nil?

      expected_seq = @state["move_seq"].to_i
      if @move_seq.to_i != expected_seq
        @error = "Invalid move sequence (possible replay attack)"
        return false
      end
      true
    end
  end
end
