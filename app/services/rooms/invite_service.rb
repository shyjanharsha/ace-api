module Rooms
  class InviteService
    def initialize(room:, sender:, receiver_id:)
      @room        = room
      @sender      = sender
      @receiver_id = receiver_id
    end

    def call
      receiver = User.find(@receiver_id)

      # Validate sender is in room
      unless @room.room_players.exists?(user_id: @sender.id)
        raise Errors::Forbidden, "You are not in this room"
      end

      raise Errors::RoomClosed, "Room is not accepting players" unless @room.status_waiting?
      raise Errors::RoomFull,   "Room is full" if @room.full?

      # Create or find existing pending invitation
      invitation = Invitation.find_or_create_by!(
        sender_id:   @sender.id,
        receiver_id: receiver.id,
        room_id:     @room.id
      ) do |inv|
        inv.status     = "pending"
        inv.expires_at = ENV.fetch("INVITATION_EXPIRY_HOURS", 24).to_i.hours.from_now
      end

      # Send in-app notification
      Notification.create!(
        user_id:    receiver.id,
        actor_id:   @sender.id,
        notif_type: "game_invite",
        title:      "#{@sender.username} invited you to play!",
        body:       "Room: #{@room.code}",
        payload:    { room_id: @room.id, invitation_id: invitation.id },
        sent_at:    Time.current
      )

      # Send push notification
      PushNotificationJob.perform_later(
        receiver.id,
        title: "Game Invite",
        body:  "#{@sender.username} invited you to play Kazhutha Kali!",
        data:  { type: "game_invite", room_id: @room.id.to_s }
      )

      # Schedule expiry
      InvitationExpiryJob.set(wait: invitation.expires_at - Time.current).perform_later(invitation.id)

      invitation
    end
  end
end
