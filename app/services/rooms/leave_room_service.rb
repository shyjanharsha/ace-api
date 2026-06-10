module Rooms
  class LeaveRoomService
    def initialize(room:, user:)
      @room = room
      @user = user
    end

    def call
      room_player = @room.room_players.find_by(user_id: @user.id)
      return unless room_player

      if @room.status_playing?
        # Mid-game leave — mark as disconnected, don't remove
        room_player.update!(status: "left")
        # If only 1 player remains, end the game
        if @room.room_players.active_status.count <= 1
          current_match = @room.current_match
          current_match&.abandon!
          @room.update!(status: "cancelled")
        end
      else
        # Lobby leave — remove seat
        room_player.destroy

        # If host leaves, transfer host or close room
        if @room.host_id == @user.id
          next_host = @room.room_players.active_status.first&.user
          if next_host
            @room.update!(host_id: next_host.id)
          else
            @room.update!(status: "cancelled")
          end
        end
      end

      @user.user_presence&.mark_online!
    end
  end
end
