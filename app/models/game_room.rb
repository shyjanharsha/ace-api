class GameRoom < ApplicationRecord
  # -------------------------------------------------------
  # Enums
  # -------------------------------------------------------
  enum status:    { waiting: "waiting", playing: "playing", finished: "finished", cancelled: "cancelled" }, _prefix: true
  enum room_type: { public: "public", private: "private" }, _prefix: true

  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :host, class_name: "User"
  has_many   :room_players, foreign_key: :room_id, dependent: :destroy
  has_many   :players, through: :room_players, source: :user
  has_many   :matches, foreign_key: :game_room_id, dependent: :destroy
  has_many   :invitations, foreign_key: :room_id, dependent: :destroy

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates :code,        presence: true, uniqueness: true, length: { is: 6 }
  validates :max_players, inclusion: { in: 2..8 }
  validates :min_players, inclusion: { in: 2..8 }
  validates :bet_coins,   numericality: { greater_than_or_equal_to: 0 }

  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_validation :generate_join_code, on: :create

  # -------------------------------------------------------
  # Scopes
  # -------------------------------------------------------
  scope :open,     -> { where(status: :waiting) }
  scope :public_rooms, -> { where(room_type: :public, status: :waiting) }
  scope :joinable, -> { where(status: :waiting) }

  # -------------------------------------------------------
  # Instance methods
  # -------------------------------------------------------
  def full?
    room_players.active_status.count >= max_players
  end

  def active_player_count
    room_players.where(status: "active").count
  end

  def can_start?
    active_player_count >= min_players && status_waiting?
  end

  def current_match
    matches.where(status: "active").first
  end

  def config_value(key, default = nil)
    config.fetch(key.to_s, default)
  end

  def move_timeout
    config_value("move_timeout_seconds", ENV.fetch("GAME_MOVE_TIMEOUT_SECONDS", 30).to_i)
  end

  private

  def generate_join_code
    loop do
      self.code = SecureRandom.alphanumeric(6).upcase
      break unless GameRoom.exists?(code: code)
    end
  end
end
