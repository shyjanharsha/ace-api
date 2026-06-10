class UserPresence < ApplicationRecord
  STATUSES = %w[online away in_game offline].freeze

  belongs_to :user
  belongs_to :current_room, class_name: "GameRoom", optional: true

  validates :user_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :online,  -> { where(status: %w[online in_game]) }
  scope :in_game, -> { where(status: "in_game") }
  scope :stale,   -> { where("last_seen_at < ?", 5.minutes.ago) }

  def mark_online!(room_id: nil)
    update!(status: "online", last_seen_at: Time.current, current_room_id: room_id)
  end

  def mark_in_game!(room_id)
    update!(status: "in_game", last_seen_at: Time.current, current_room_id: room_id)
  end

  def mark_offline!
    update!(status: "offline", last_seen_at: Time.current, current_room_id: nil)
  end

  def heartbeat!
    touch(:last_seen_at)
  end
end
