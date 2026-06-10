class ContactSync < ApplicationRecord
  belongs_to :user
  belongs_to :matched_user, class_name: "User", optional: true

  validates :phone_hash, presence: true
  validates :phone_hash, uniqueness: { scope: :user_id }

  scope :matched, -> { where.not(matched_user_id: nil) }
end
