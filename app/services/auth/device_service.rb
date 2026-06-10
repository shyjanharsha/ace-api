module Auth
  class DeviceService
    def initialize(user:, device_uid:, platform:, fcm_token: nil)
      @user       = user
      @device_uid = device_uid
      @platform   = platform
      @fcm_token  = fcm_token
    end

    def register_or_update
      device = @user.devices.find_or_initialize_by(device_uid: @device_uid)
      device.update!(
        platform: @platform,
        token:    @fcm_token || device.token || "pending",
        active:   true
      )
      device
    end

    def update_fcm_token(token)
      @user.devices.find_by(device_uid: @device_uid)&.update!(token: token, active: true)
    end

    def deactivate
      @user.devices.find_by(device_uid: @device_uid)&.update!(active: false)
    end
  end
end
