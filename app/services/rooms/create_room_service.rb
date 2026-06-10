module Rooms
  class CreateRoomService
    def initialize(host:, params:)
      @host   = host
      @params = params
    end

    def call
      bet_coins = @params[:bet_coins].to_i

      # Validate coins for wager
      if bet_coins > 0 && @host.coins < bet_coins
        raise Errors::InsufficientCoins, "You need #{bet_coins} coins to create this room (you have #{@host.coins})"
      end

      max_players = (@params[:max_players] || 4).to_i.clamp(2, 8)

      room = GameRoom.create!(
        host_id:     @host.id,
        room_type:   @params[:room_type] || "public",
        max_players: max_players,
        min_players: (@params[:min_players] || 2).to_i.clamp(2, max_players),
        bet_coins:   bet_coins,
        config:      build_config
      )

      # Add host as first player (seat 0)
      room.room_players.create!(user_id: @host.id, seat_position: 0, status: "active")

      # Update presence
      @host.user_presence&.mark_online!(room_id: room.id)

      room
    end

    private

    def build_config
      {
        "move_timeout_seconds" => (@params[:move_timeout] || 30).to_i.clamp(15, 60),
        "allow_spectators"     => @params[:allow_spectators] || false
      }
    end
  end
end
