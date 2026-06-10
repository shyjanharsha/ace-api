class PresenceCleanupJob < ApplicationJob
  queue_as :low

  # Marks user offline if they haven't heartbeated recently
  def perform(user_id)
    presence = UserPresence.find_by(user_id: user_id)
    return unless presence
    return if presence.status == "offline"

    # If last seen > 30s ago, mark offline (missed reconnection window)
    if presence.last_seen_at < 30.seconds.ago
      presence.mark_offline!

      # Broadcast offline to friends via ActionCable
      user = User.find_by(id: user_id)
      if user
        friend_ids = user.accepted_friends.pluck(:id)
        friend_ids.each do |fid|
          ActionCable.server.broadcast("presence_user_#{fid}", {
            type: "friend_presence",
            data: { user_id: user_id, status: "offline" }
          })
        end
      end
    end
  end
end
