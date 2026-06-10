class RoomPlayer < ApplicationRecord
  enum status: { active: "active", disconnected: "disconnected", left: "left", kicked: "kicked" }, _prefix: true

  belongs_to :room, class_name: "GameRoom", foreign_key: :room_id
  belongs_to :user

  validates :seat_position, presence: true, uniqueness: { scope: :room_id }
  validates :user_id, uniqueness: { scope: :room_id, message: "already in this room" }

  scope :active_status, -> { where(status: "active") }
  scope :connected, -> { where(status: %w[active]) }
end
