module Api
  module V1
    class PresencesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/presences/friends
      def friends
        friends_list = current_user.accepted_friends.includes(:user_presence)
        payload = friends_list.map do |friend|
          {
            id: friend.id,
            username: friend.username,
            display_name: friend.display_name,
            avatar_url: friend.avatar_url,
            status: friend.user_presence&.status || "offline",
            last_seen_at: friend.user_presence&.last_seen_at&.iso8601
          }
        end
        render_success(payload)
      end
    end
  end
end
