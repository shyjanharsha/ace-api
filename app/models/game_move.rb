class GameMove < ApplicationRecord
  enum move_type: { play: "play", auto_play: "auto_play", timeout_skip: "timeout_skip" }, _prefix: true

  belongs_to :match
  belongs_to :player, class_name: "User", foreign_key: :player_id

  validates :card_played, presence: true
  validates :move_seq,    presence: true, uniqueness: { scope: :match_id }
  validates :played_at,   presence: true

  scope :for_trick, ->(trick_num) { where(trick_number: trick_num).order(:move_seq) }
  scope :cuts,      -> { where(is_cut: true) }
  scope :ordered,   -> { order(:move_seq) }
end
