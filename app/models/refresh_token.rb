class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_hash, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active,   -> { where(revoked: false).where("expires_at > ?", Time.current) }
  scope :expired,  -> { where("expires_at <= ?", Time.current) }
  scope :revoked,  -> { where(revoked: true) }

  def expired?
    expires_at <= Time.current
  end

  def valid_token?
    !revoked && !expired?
  end

  def revoke!
    update!(revoked: true)
  end

  def self.cleanup_expired!
    expired.delete_all
  end
end
