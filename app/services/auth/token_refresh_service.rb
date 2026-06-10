module Auth
  class TokenRefreshService
    def initialize(raw_refresh_token:, device_uid: nil)
      @raw_token  = raw_refresh_token
      @device_uid = device_uid
    end

    def call
      token_hash = Digest::SHA256.hexdigest(@raw_token)
      record     = RefreshToken.find_by(token_hash: token_hash)

      unless record&.valid_token?
        raise Errors::InvalidToken, "Refresh token is invalid or expired"
      end

      user = record.user

      # Rotate: revoke old, issue new pair atomically
      ActiveRecord::Base.transaction do
        record.revoke!
        Auth::JwtService.issue_token_pair(user, device_uid: @device_uid)
      end
    end
  end
end
