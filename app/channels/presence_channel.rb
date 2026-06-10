class PresenceChannel < ApplicationCable::Channel
  HEARTBEAT_INTERVAL = 20 # seconds

  def subscribed
    stream_from "presence_user_#{current_user.id}"
    current_user.user_presence&.mark_online!

    # Broadcast online status to friends
    broadcast_presence_to_friends("online")
  end

  def unsubscribed
    # Don't mark offline immediately — give time for reconnection
    PresenceCleanupJob.set(wait: 15.seconds).perform_later(current_user.id)
  end

  # Inbound: client sends heartbeat every HEARTBEAT_INTERVAL seconds
  def heartbeat(data)
    current_user.user_presence&.heartbeat!
  end

  private

  def broadcast_presence_to_friends(status)
    friend_ids = current_user.accepted_friends.pluck(:id)

    friend_ids.each do |friend_id|
      ActionCable.server.broadcast("presence_user_#{friend_id}", {
        type: "friend_presence",
        data: {
          user_id:  current_user.id,
          username: current_user.username,
          status:   status
        }
      })
    end
  end
end
