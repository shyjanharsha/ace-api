module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        before_action :authenticate_user!, only: [:destroy]

        # POST /api/v1/auth/login
        def create
          result = ::Auth::LoginService.new(
            identifier: params.require(:identifier),
            password:   params.require(:password),
            device_uid: params[:device_uid],
            platform:   params[:platform]
          ).call

          render_success({
            user:   user_payload(result[:user]),
            tokens: result[:tokens]
          })
        end

        # DELETE /api/v1/auth/logout
        def destroy
          ::Auth::LogoutService.new(
            user:              current_user,
            raw_refresh_token: params[:refresh_token],
            device_uid:        params[:device_uid]
          ).call

          render_success({ message: "Logged out successfully" })
        end

        private

        def user_payload(user)
          {
            id:           user.id,
            username:     user.username,
            display_name: user.display_name,
            is_guest:     user.is_guest,
            verified:     user.verified,
            coins:        user.coins,
            level:        user.level,
            avatar_url:   user.avatar_url
          }
        end
      end
    end
  end
end
