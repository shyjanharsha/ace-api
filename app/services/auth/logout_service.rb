module Auth
  class LogoutService
    def initialize(user:, raw_refresh_token: nil, device_uid: nil)
      @user              = user
      @raw_refresh_token = raw_refresh_token
      @device_uid        = device_uid
    end

    def call
      # Revoke refresh token
      if @raw_refresh_token.present?
        token_hash = Digest::SHA256.hexdigest(@raw_refresh_token)
        RefreshToken.find_by(token_hash: token_hash)&.revoke!
      end

      # Deactivate device FCM token
      if @device_uid.present?
        @user.devices.find_by(device_uid: @device_uid)&.update!(active: false)
      end

      # Mark offline
      @user.user_presence&.mark_offline!

      true
    end
  end
end
