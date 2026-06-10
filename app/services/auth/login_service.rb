module Auth
  class LoginService
    def initialize(identifier:, password:, device_uid: nil, platform: nil)
      @identifier = identifier
      @password   = password
      @device_uid = device_uid
      @platform   = platform
    end

    def call
      user = User.find_by_login(@identifier)

      unless user && user.authenticate(@password)
        raise Errors::Unauthorized, "Invalid credentials"
      end

      if user.is_guest
        raise Errors::Unauthorized, "Guest accounts cannot use password login"
      end

      tokens = Auth::JwtService.issue_token_pair(user, device_uid: @device_uid)

      # Register device if provided
      if @device_uid.present? && @platform.present?
        Auth::DeviceService.new(
          user: user,
          device_uid: @device_uid,
          platform: @platform
        ).register_or_update
      end

      { user: user, tokens: tokens }
    end
  end
end
