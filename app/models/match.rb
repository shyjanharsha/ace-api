class Match < ApplicationRecord
  # -------------------------------------------------------
  # Associations
  # -------------------------------------------------------
  belongs_to :game_room
  belongs_to :winner, class_name: "User", optional: true
  has_many   :match_players, dependent: :destroy
  has_many   :players, through: :match_players, source: :user
  has_many   :game_moves, dependent: :destroy

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates :status, inclusion: { in: %w[active completed abandoned] }

  # -------------------------------------------------------
  # Scopes
  # -------------------------------------------------------
  scope :active,    -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :recent,    -> { order(created_at: :desc) }

  # -------------------------------------------------------
  # Game State Accessors
  # (game_state is the canonical server JSONB — never expose hands publicly)
  # -------------------------------------------------------

  # Returns hand for a specific player (used for private channel broadcast)
  def hand_for(player_id)
    game_state.dig("hands", player_id.to_s) || []
  end

  def set_hand_for(player_id, cards)
    game_state["hands"] ||= {}
    game_state["hands"][player_id.to_s] = cards
    save!
  end

  def current_turn_player_id
    game_state["current_turn"]
  end

  def leading_suit
    game_state["leading_suit"]
  end

  def trick_pile
    game_state["trick_pile"] || []
  end

  def active_player_ids
    game_state["active_players"] || []
  end

  def finished_player_ids
    game_state["finished_players"] || []
  end

  def move_sequence
    game_state["move_seq"] || 0
  end

  def increment_move_seq!
    game_state["move_seq"] = (game_state["move_seq"] || 0) + 1
    save!
  end

  # -------------------------------------------------------
  # Replay data
  # -------------------------------------------------------
  def append_to_replay!(move_entry)
    replay_data << move_entry
    save!
  end

  # -------------------------------------------------------
  # Completion
  # -------------------------------------------------------
  def complete!(winner_user)
    update!(
      status: "completed",
      winner_id: winner_user.id,
      ended_at: Time.current
    )
  end

  def abandon!
    update!(status: "abandoned", ended_at: Time.current)
  end

  def duration_seconds
    return nil unless started_at && ended_at
    (ended_at - started_at).to_i
  end
end
