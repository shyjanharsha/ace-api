class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = GameRoom.find_by(id: params[:room_id])

    if @room.nil?
      reject and return
    end

    # Join the room stream (all players in the room receive this)
    stream_from "room_#{@room.id}"

    # Update presence
    current_user.user_presence&.mark_online!(room_id: @room.id)

    # Broadcast join event to others
    broadcast_to_room("user_joined", {
      user: { id: current_user.id, username: current_user.username, avatar_url: current_user.avatar_url },
      player_count: @room.active_player_count
    })

    # Send current room state to the subscriber
    transmit({ type: "room_state", data: room_state_payload })
  end

  def unsubscribed
    return unless @room

    current_user.user_presence&.mark_online!

    # Handle leave logic
    Rooms::LeaveRoomService.new(room: @room, user: current_user).call

    broadcast_to_room("user_left", {
      user_id: current_user.id,
      username: current_user.username,
      player_count: @room.reload.active_player_count
    })
  end

  # Inbound: client sends chat message
  def send_chat(data)
    message = data["message"].to_s.strip
    return if message.blank? || message.length > 200

    broadcast_to_room("chat_message", {
      user_id:    current_user.id,
      username:   current_user.username,
      avatar_url: current_user.avatar_url,
      message:    message,
      sent_at:    Time.current.iso8601
    })
  end

  # Inbound: player marks themselves ready
  def set_ready(data)
    Rails.logger.info "\n\n=== SET_READY CALLED for User #{current_user&.id} ==="
    Rails.logger.info "Room: #{@room&.id}, Data: #{data.inspect}"

    room_player = @room.room_players.find_by(user_id: current_user.id)
    
    if room_player.nil?
      Rails.logger.error "=== FAILED: RoomPlayer not found for User #{current_user.id} ==="
      return 
    end

    room_player.update!(ready: data["ready"])
    Rails.logger.info "=== SUCCESS: Updated ready status to #{data["ready"]} ==="

    broadcast_to_room("player_ready", {
      user_id: current_user.id,
      ready:   data["ready"]
    })
  end

  private

  def broadcast_to_room(event_type, payload)
    ActionCable.server.broadcast("room_#{@room.id}", {
      type:    event_type,
      data:    payload,
      room_id: @room.id
    })
  end

  def room_state_payload
    players = @room.room_players.includes(:user).map do |rp|
      {
        user_id:       rp.user_id,
        username:      rp.user.username,
        avatar_url:    rp.user.avatar_url,
        seat_position: rp.seat_position,
        status:        rp.status,
        ready:         rp.ready
      }
    end

    {
      room_id:     @room.id,
      code:        @room.code,
      status:      @room.status,
      host_id:     @room.host_id,
      max_players: @room.max_players,
      bet_coins:   @room.bet_coins,
      players:     players
    }
  end
end
