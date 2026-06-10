module Api
  module V1
    class FriendshipsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_friendship, only: [:update, :destroy]

      # GET /api/v1/friendships
      def index
        friendships = Friendship.involving(current_user.id).includes(:requester, :receiver)
        render_success(friendships.map { |f| friendship_payload(f) })
      end

      # POST /api/v1/friendships (send request)
      def create
        receiver = User.find(params.require(:receiver_id))
        friendship = Friendship.find_or_create_by!(requester_id: current_user.id, receiver_id: receiver.id) do |f|
          f.status = "pending"
        end

        # Notify receiver
        Notification.create!(
          user_id: receiver.id, actor_id: current_user.id,
          notif_type: "friend_request", title: "Friend Request",
          body: "#{current_user.username} sent you a friend request",
          payload: { friendship_id: friendship.id }, sent_at: Time.current
        )
        PushNotificationJob.perform_later(receiver.id, title: "Friend Request",
          body: "#{current_user.username} wants to be your friend!", data: { type: "friend_request" })

        render_created(friendship_payload(friendship))
      end

      # PATCH /api/v1/friendships/:id (accept/decline/block)
      def update
        raise Errors::Forbidden, "Not your request" unless @friendship.receiver_id == current_user.id

        action = params.require(:action_type)
        case action
        when "accept"
          @friendship.update!(status: "accepted")
          # Notify requester
          Notification.create!(
            user_id: @friendship.requester_id, actor_id: current_user.id,
            notif_type: "friend_accepted", title: "Friend Request Accepted",
            body: "#{current_user.username} accepted your friend request",
            payload: {}, sent_at: Time.current
          )
        when "decline"
          @friendship.update!(status: "declined")
        when "block"
          @friendship.update!(status: "blocked")
        else
          raise Errors::UnprocessableEntity, "Invalid action"
        end

        render_success(friendship_payload(@friendship))
      end

      # DELETE /api/v1/friendships/:id
      def destroy
        @friendship.destroy
        render_success({ message: "Friendship removed" })
      end

      private

      def set_friendship
        @friendship = Friendship.involving(current_user.id).find(params[:id])
      end

      def friendship_payload(f)
        {
          id:           f.id,
          status:       f.status,
          requester:    {
            id: f.requester_id,
            username: f.requester.username,
            display_name: f.requester.display_name,
            avatar_url: f.requester.avatar_url
          },
          receiver:     {
            id: f.receiver_id,
            username: f.receiver.username,
            display_name: f.receiver.display_name,
            avatar_url: f.receiver.avatar_url
          },
          created_at:   f.created_at.iso8601
        }
      end
    end
  end
end
