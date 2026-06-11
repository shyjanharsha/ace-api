class GameChannel < ApplicationCable::Channel
  def subscribed
    @match = Match.find_by(id: params[:match_id])

    if @match.nil? || @match.status == "abandoned"
      reject and return
    end

    # Check player is in this match
    @match_player = @match.match_players.find_by(user_id: current_user.id)
    if @match_player.nil?
      reject and return
    end

    # Public game stream (receives broadcasts safe for all players: moves, trick results, etc.)
    stream_from "game_#{@match.id}"

    # Private stream (receives ONLY this player's hand, turn notifications)
    stream_from "game_#{@match.id}_player_#{current_user.id}"

    # Handle reconnection
    reconnect_if_needed
  end

  def unsubscribed
    return unless @match && @match_player

    # Mark player as disconnected (give 30s reconnection window)
    rp = @match.game_room.room_players.find_by(user_id: current_user.id)
    rp&.update!(status: "disconnected")

    # Broadcast disconnect to others
    ActionCable.server.broadcast("game_#{@match.id}", {
      type: "player_disconnected",
      data: {
        user_id:  current_user.id,
        username: current_user.username,
        timeout:  30
      }
    })

    # Schedule presence cleanup after reconnection window
    PresenceCleanupJob.set(wait: 30.seconds).perform_later(current_user.id)

    # If it's this player's turn, schedule auto-play
    if @match.game_state["current_turn"] == current_user.id
      timeout = @match.game_room.move_timeout
      GameMoveTimeoutJob.set(wait: timeout.seconds).perform_later(
        @match.id,
        current_user.id,
        @match.move_sequence
      )
    end
  end

  def reconnect
    GameEngine::ReconnectHandler.new(@match, current_user).restore!
  end

  private

  def reconnect_if_needed
    rp = @match.game_room.room_players.find_by(user_id: current_user.id)

    if rp&.status == "disconnected"
      # Restore connection
      rp.update!(status: "active")
      current_user.user_presence&.mark_in_game!(@match.game_room_id)

      # Send private state (player's hand)
      GameEngine::ReconnectHandler.new(@match, current_user).restore!

      # Notify others of reconnection
      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "player_reconnected",
        data: { user_id: current_user.id, username: current_user.username }
      })
    else
      # New join — mark in_game
      rp&.update!(status: "active")
      current_user.user_presence&.mark_in_game!(@match.game_room_id)
      
      # Send the initial state anyway due to race conditions where
      # the game start broadcast finishes before the client subscribes here.
      GameEngine::ReconnectHandler.new(@match, current_user).restore!
    end
  end
end
