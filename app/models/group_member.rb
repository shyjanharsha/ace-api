class GroupMember < ApplicationRecord
  enum role: { member: "member", admin: "admin" }, _prefix: true

  belongs_to :group
  belongs_to :user

  validates :user_id, uniqueness: { scope: :group_id, message: "already a member" }

  scope :admins,   -> { where(role: "admin") }
  scope :members,  -> { where(role: "member") }
end
