class Notification < ApplicationRecord
  TYPES = %w[
    friend_request friend_accepted game_invite
    game_started game_over group_invite system
  ].freeze

  belongs_to :user
  belongs_to :actor, class_name: "User", optional: true

  validates :notif_type, inclusion: { in: TYPES }
  validates :title, presence: true

  scope :unread,   -> { where(read: false) }
  scope :recent,   -> { order(sent_at: :desc) }
  scope :for_type, ->(type) { where(notif_type: type) }

  def mark_read!
    update!(read: true)
  end

  def self.mark_all_read!(user_id)
    where(user_id: user_id, read: false).update_all(read: true)
  end
end
