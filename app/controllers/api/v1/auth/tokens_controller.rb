module Api
  module V1
    module Auth
      class TokensController < ApplicationController
        # POST /api/v1/auth/refresh
        def create
          tokens = ::Auth::TokenRefreshService.new(
            raw_refresh_token: params.require(:refresh_token),
            device_uid:        params[:device_uid]
          ).call

          render_success({ tokens: tokens })
        end

        # POST /api/v1/auth/devices
        def register_device
          authenticate_user!
          device = ::Auth::DeviceService.new(
            user:       current_user,
            device_uid: params.require(:device_uid),
            platform:   params.require(:platform),
            fcm_token:  params.require(:fcm_token)
          ).register_or_update

          render_success({ device_uid: device.device_uid, platform: device.platform })
        end
      end
    end
  end
end
