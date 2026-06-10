class GameMoveTimeoutJob < ApplicationJob
  queue_as :critical

  # Called N seconds after a player's turn begins.
  # Only auto-plays if the player hasn't moved (move_seq matches).
  def perform(match_id, player_id, expected_move_seq)
    match = Match.find_by(id: match_id)
    return unless match&.status == "active"

    # If move_seq has advanced, the player already played — no action needed
    current_seq = match.game_state["move_seq"].to_i
    return if current_seq != expected_move_seq.to_i

    # Auto-play
    result = GameEngine::AutoPlayService.new(
      match:     match,
      player_id: player_id,
      move_seq:  expected_move_seq
    ).call

    Rails.logger.info "[GameMoveTimeoutJob] match=#{match_id} player=#{player_id} auto_played=#{result}"
  rescue => e
    Rails.logger.error "[GameMoveTimeoutJob] Error: #{e.message}"
  end
end
