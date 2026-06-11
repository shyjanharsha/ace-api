module GameEngine
  # Builds and manages a standard 52-card deck
  class DeckService
    SUITS  = %w[spades hearts diamonds clubs].freeze
    RANKS  = %w[2 3 4 5 6 7 8 9 T J Q K A].freeze
    VALUES = { "2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9,"T"=>10,"J"=>11,"Q"=>12,"K"=>13,"A"=>14 }.freeze

    SUIT_CODES = { "spades" => "S", "hearts" => "H", "diamonds" => "D", "clubs" => "C" }.freeze

    # Returns shuffled array of 52 card hashes
    def self.build_and_shuffle
      deck = SUITS.flat_map do |suit|
        RANKS.map do |rank|
          {
            suit:  suit,
            rank:  rank,
            code:  "#{rank}#{SUIT_CODES[suit]}",
            value: VALUES[rank]
          }
        end
      end
      deck.shuffle
    end

    def self.card_value(code)
      rank = code[0..-2]  # all chars except last (suit)
      VALUES[rank] || 0
    end

    def self.card_suit(code)
      suit_code = code[-1]
      SUIT_CODES.key(suit_code)
    end

    def self.ace_of_spades_code
      "AS"
    end
  end
end
