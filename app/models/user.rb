class User < ApplicationRecord
  has_secure_password validations: false  # validations false to allow guests without password

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  has_many :devices,          dependent: :destroy
  has_many :refresh_tokens,   dependent: :destroy
  has_one  :player_statistic, dependent: :destroy
  has_one  :user_presence,    dependent: :destroy

  # Game associations
  has_many :hosted_rooms,   class_name: "GameRoom",   foreign_key: :host_id, dependent: :nullify
  has_many :room_players,   dependent: :destroy
  has_many :game_rooms,     through: :room_players
  has_many :match_players,  dependent: :destroy
  has_many :matches,        through: :match_players
  has_many :game_moves,     foreign_key: :player_id, dependent: :destroy

  # Social associations
  has_many :sent_friendships,     class_name: "Friendship", foreign_key: :requester_id, dependent: :destroy
  has_many :received_friendships, class_name: "Friendship", foreign_key: :receiver_id,  dependent: :destroy
  has_many :friends, through: :sent_friendships, source: :receiver

  has_many :owned_groups,  class_name: "Group", foreign_key: :owner_id, dependent: :destroy
  has_many :group_members, dependent: :destroy
  has_many :groups,        through: :group_members

  has_many :sent_invitations,     class_name: "Invitation", foreign_key: :sender_id,   dependent: :destroy
  has_many :received_invitations, class_name: "Invitation", foreign_key: :receiver_id, dependent: :destroy

  has_many :notifications, dependent: :destroy
  has_many :contact_syncs, dependent: :destroy

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, underscores" }

  validates :email, uniqueness: true, allow_blank: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone, uniqueness: true, allow_blank: true

  validates :coins, numericality: { greater_than_or_equal_to: 0 }
  validates :level, numericality: { greater_than: 0 }

  # Guests need no password; real users do
  validates :password, presence: true, length: { minimum: 6 }, if: -> { !is_guest && password.present? }
  validates :password, presence: true, on: :create, if: -> { !is_guest }

  # -------------------------------------------------------
  # Scopes
  # -------------------------------------------------------
  scope :guests,    -> { where(is_guest: true) }
  scope :verified,  -> { where(verified: true) }
  scope :online,    -> { joins(:user_presence).where(user_presences: { status: %w[online in_game] }) }
  scope :in_game,   -> { joins(:user_presence).where(user_presences: { status: "in_game" }) }
  scope :by_level,  -> { order(level: :desc) }

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  after_create :create_player_statistic_record
  after_create :create_user_presence_record

  # -------------------------------------------------------
  # Class methods
  # -------------------------------------------------------
  def self.find_by_login(identifier)
    find_by(email: identifier) || find_by(phone: identifier) || find_by(username: identifier)
  end

  # -------------------------------------------------------
  # Instance methods
  # -------------------------------------------------------
  def online?
    user_presence&.status.in?(%w[online in_game])
  end

  def in_game?
    user_presence&.status == "in_game"
  end

  def add_coins!(amount)
    increment!(:coins, amount)
  end

  def deduct_coins!(amount)
    raise "Insufficient coins" if coins < amount
    decrement!(:coins, amount)
  end

  def add_xp!(amount)
    increment!(:xp, amount)
    check_level_up!
  end

  def accepted_friends
    friend_ids_sent     = sent_friendships.accepted.pluck(:receiver_id)
    friend_ids_received = received_friendships.accepted.pluck(:requester_id)
    User.where(id: friend_ids_sent + friend_ids_received)
  end

  private

  def create_player_statistic_record
    create_player_statistic unless player_statistic
  end

  def create_user_presence_record
    create_user_presence(status: "offline", last_seen_at: Time.current) unless user_presence
  end

  def check_level_up!
    required_xp = level * 500
    if xp >= required_xp
      increment!(:level)
    end
  end
end
