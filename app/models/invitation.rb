class Invitation < ApplicationRecord
  STATUSES = %w[pending accepted declined expired cancelled].freeze

  belongs_to :sender,   class_name: "User"
  belongs_to :receiver, class_name: "User"
  belongs_to :room,     class_name: "GameRoom"

  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true
  validates :sender_id, uniqueness: { scope: [:receiver_id, :room_id] }

  scope :pending,  -> { where(status: "pending") }
  scope :active,   -> { pending.where("expires_at > ?", Time.current) }
  scope :expired,  -> { pending.where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def accept!
    update!(status: "accepted")
  end

  def decline!
    update!(status: "declined")
  end

  def expire!
    update!(status: "expired")
  end
end
