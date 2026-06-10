class Friendship < ApplicationRecord
  # -------------------------------------------------------
  # Enums
  # -------------------------------------------------------
  enum status: { pending: "pending", accepted: "accepted", blocked: "blocked", declined: "declined" }, _prefix: true

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :requester, class_name: "User"
  belongs_to :receiver,  class_name: "User"

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates :requester_id, uniqueness: { scope: :receiver_id, message: "already sent" }
  validate  :cannot_friend_self

  # -------------------------------------------------------
  # Scopes
  # -------------------------------------------------------
  scope :pending,  -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :involving, ->(user_id) { where("requester_id = ? OR receiver_id = ?", user_id, user_id) }

  private

  def cannot_friend_self
    errors.add(:receiver_id, "cannot friend yourself") if requester_id == receiver_id
  end
end
