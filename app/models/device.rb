class Device < ApplicationRecord
  belongs_to :user

  validates :token,      presence: true
  validates :platform,   inclusion: { in: %w[ios android web] }
  validates :device_uid, uniqueness: { scope: :user_id }

  scope :active,    -> { where(active: true) }
  scope :ios,       -> { where(platform: "ios") }
  scope :android,   -> { where(platform: "android") }
end
