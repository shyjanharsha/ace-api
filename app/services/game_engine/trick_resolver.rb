module GameEngine
  # Determines the outcome of a trick (all active players have played one card)
  # Kazhutha Kali rules:
  # - Highest card of the LEADING suit wins the trick
  # - Off-suit (cut) cards do NOT win
  # - If a cut occurred: cutter starts next trick, leading-suit winner collects pile
  class TrickResolver
    def initialize(match)
      @match = match
      @state = match.game_state
    end

    # Returns: { winner_id:, collected_cards:, was_cut:, cutter_id: }
    def resolve
      trick_pile    = @state["trick_pile"]
      leading_suit  = @state["leading_suit"]

      # Separate leading-suit plays from cuts
      suit_plays = trick_pile.select { |move| GameEngine::DeckService.card_suit(move["card"]) == leading_suit }
      cut_plays  = trick_pile.reject { |move| GameEngine::DeckService.card_suit(move["card"]) == leading_suit }

      was_cut   = cut_plays.any?
      cutter_id = cut_plays.first&.dig("player_id")

      # Winner of original suit = highest card of leading suit
      suit_winner = suit_plays.max_by { |move| GameEngine::DeckService.card_value(move["card"]) }
      winner_id   = suit_winner["player_id"]

      collected_cards = trick_pile.map { |m| m["card"] }

      {
        winner_id:       winner_id,
        collected_cards: collected_cards,
        was_cut:         was_cut,
        cutter_id:       cutter_id,
        # If cut: cutter leads next trick; if no cut: suit winner leads
        next_leader_id:  was_cut ? cutter_id : winner_id
      }
    end
  end
end
