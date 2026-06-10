module Api
  module V1
    class InvitationsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/invitations
      def index
        invitations = current_user.received_invitations.active.includes(:sender, :room)
        render_success(invitations.map { |inv| invitation_payload(inv) })
      end

      # POST /api/v1/invitations
      def create
        room = GameRoom.find(params.require(:room_id))
        invitation = Rooms::InviteService.new(
          room:        room,
          sender:      current_user,
          receiver_id: params.require(:receiver_id)
        ).call
        render_created(invitation_payload(invitation))
      end

      # PATCH /api/v1/invitations/:id
      def update
        invitation = current_user.received_invitations.find(params[:id])
        case params.require(:status)
        when "accepted"
          invitation.accept!
          Rooms::JoinRoomService.new(room: invitation.room, user: current_user).call
        when "declined"
          invitation.decline!
        else
          raise Errors::UnprocessableEntity, "Invalid status"
        end
        render_success(invitation_payload(invitation))
      end

      private

      def invitation_payload(inv)
        {
          id:         inv.id,
          status:     inv.status,
          expires_at: inv.expires_at.iso8601,
          sender:     { id: inv.sender_id, username: inv.sender.username },
          room:       { id: inv.room_id, code: inv.room.code, bet_coins: inv.room.bet_coins }
        }
      end
    end
  end
end
