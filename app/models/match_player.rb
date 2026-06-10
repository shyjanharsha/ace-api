class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :user

  validates :match_id, uniqueness: { scope: :user_id }
  validates :seat_position, presence: true, numericality: true

  scope :donkeys,  -> { where(is_donkey: true) }
  scope :winners,  -> { where(is_donkey: false).order(:final_rank) }
  scope :finished, -> { where.not(finished_at: nil) }

  def mark_finished!(rank)
    update!(final_rank: rank, finished_at: Time.current)
  end

  def mark_donkey!
    update!(is_donkey: true)
  end
end
