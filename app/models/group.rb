class Group < ApplicationRecord
  enum group_type: { public: "public", private: "private" }, _prefix: true

  belongs_to :owner, class_name: "User"
  has_many   :group_members, dependent: :destroy
  has_many   :members, through: :group_members, source: :user

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }

  before_create :generate_invite_code

  def admin_ids
    group_members.where(role: "admin").pluck(:user_id)
  end

  def admin?(user)
    group_members.exists?(user_id: user.id, role: "admin")
  end

  private

  def generate_invite_code
    self.invite_code = SecureRandom.alphanumeric(8).upcase
  end
end
