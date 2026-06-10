module Rooms
  class JoinRoomService
    def initialize(room:, user:)
      @room = room
      @user = user
    end

    def call
      raise Errors::RoomClosed, "Room is not accepting players" unless @room.status_waiting?
      raise Errors::RoomFull,   "Room is full (#{@room.max_players} players max)" if @room.full?

      # Check if user already in room
      if @room.room_players.exists?(user_id: @user.id)
        return @room.room_players.find_by(user_id: @user.id)
      end

      bet = @room.bet_coins
      if bet > 0 && @user.coins < bet
        raise Errors::InsufficientCoins, "You need #{bet} coins to join (you have #{@user.coins})"
      end

      next_seat = next_available_seat
      room_player = @room.room_players.create!(
        user_id:       @user.id,
        seat_position: next_seat,
        status:        "active"
      )

      @user.user_presence&.mark_online!(room_id: @room.id)
      room_player
    end

    private

    def next_available_seat
      taken = @room.room_players.pluck(:seat_position)
      (0...@room.max_players).find { |s| !taken.include?(s) }
    end
  end
end
