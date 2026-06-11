module Api
  module V1
    class RoomsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_room, only: %i[show join leave start chat]

      # GET /api/v1/rooms
      def index
        pagy, rooms = pagy(GameRoom.public_rooms.includes(:host, :room_players), items: 20)
        render_success(rooms.map { |r| room_payload(r) }, meta: pagy_meta(pagy))
      end

      # POST /api/v1/rooms
      def create
        room = Rooms::CreateRoomService.new(host: current_user, params: room_params).call
        render_created(room_payload(room))
      end

      # GET /api/v1/rooms/:id
      def show
        puts "Room 11: #{@room}"
        render_success(room_payload_detailed(@room))
      end

      # POST /api/v1/rooms/:id/join
      def join
        Rooms::JoinRoomService.new(room: @room, user: current_user).call
        render_success(room_payload_detailed(@room.reload))
      end

      # POST /api/v1/rooms/join_by_code
      def join_by_code
        @room = GameRoom.find_by(code: params.require(:code).upcase)
        raise Errors::NotFound, "Room not found with code #{params[:code]}" unless @room

        Rooms::JoinRoomService.new(room: @room, user: current_user).call

        # Broadcast via ActionCable
        ActionCable.server.broadcast("room_#{@room.id}", {
                                       type: 'user_joined',
                                       data: { user_id: current_user.id, username: current_user.username }
                                     })

        puts "User joined room: #{current_user.username}"
        puts "Room: #{@room}"

        render_success(room_payload_detailed(@room.reload))
      end

      # DELETE /api/v1/rooms/:id/leave
      def leave
        Rooms::LeaveRoomService.new(room: @room, user: current_user).call
        render_success({ message: 'Left room successfully' })
      end

      # POST /api/v1/rooms/:id/start
      def start
        raise Errors::Forbidden, 'Only the host can start the game' unless @room.host_id == current_user.id
        raise Errors::UnprocessableEntity, "Not enough players (min #{@room.min_players})" unless @room.can_start?

        # Create match record
        player_ids = @room.room_players.active_status.order(:seat_position).pluck(:user_id)
        match = Match.create!(
          game_room_id: @room.id,
          status: 'active',
          started_at: Time.current
        )

        # Create match_player records
        player_ids.each_with_index do |uid, idx|
          bet = @room.bet_coins
          match.match_players.create!(
            user_id: uid,
            seat_position: idx,
            coins_wagered: bet
          )
        end

        @room.update!(status: 'playing')

        # Broadcast game_started via room channel before dealing
        ActionCable.server.broadcast("room_#{@room.id}", {
                                       type: 'game_started',
                                       data: { match_id: match.id }
                                     })

        # Deal cards (async would be ideal but do it inline for correctness)
        GameEngine::DealService.new(match, player_ids).call

        render_success({ match_id: match.id, message: 'Game started!' })
      end

      # POST /api/v1/rooms/:id/chat
      def chat
        message = params.require(:message).strip
        raise Errors::UnprocessableEntity, 'Message too long' if message.length > 200

        ActionCable.server.broadcast("room_#{@room.id}", {
                                       type: 'chat_message',
                                       data: {
                                         user_id: current_user.id,
                                         username: current_user.username,
                                         avatar_url: current_user.avatar_url,
                                         message: message,
                                         sent_at: Time.current.iso8601
                                       }
                                     })

        render_success({ sent: true })
      end

      private

      def set_room
        @room = GameRoom.find(params[:id])
      end

      def room_params
        params.permit(:room_type, :max_players, :min_players, :bet_coins, :move_timeout, :allow_spectators)
      end

      def room_payload(room)
        {
          id: room.id,
          code: room.code,
          status: room.status,
          room_type: room.room_type,
          host_id: room.host_id,
          max_players: room.max_players,
          bet_coins: room.bet_coins,
          player_count: room.room_players.count
        }
      end

      def room_payload_detailed(room)
        room_payload(room).merge({
                                   players: room.room_players.includes(:user).map do |rp|
                                     {
                                       user_id: rp.user_id,
                                       username: rp.user.username,
                                       avatar_url: rp.user.avatar_url,
                                       seat_position: rp.seat_position,
                                       status: rp.status,
                                       ready: rp.ready
                                     }
                                   end
                                 })
      end
    end
  end
end
