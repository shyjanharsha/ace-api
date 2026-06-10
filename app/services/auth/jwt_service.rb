module Auth
  class JwtService
    # -------------------------------------------------------
    # Encode an access token (short-lived)
    # -------------------------------------------------------
    def self.encode(payload, exp: JwtConfig::ACCESS_EXPIRY)
      payload = payload.dup
      payload[:exp] = exp.from_now.to_i
      payload[:iat] = Time.current.to_i
      JWT.encode(payload, JwtConfig::SECRET_KEY, JwtConfig::ALGORITHM)
    end

    # -------------------------------------------------------
    # Decode and verify an access token
    # -------------------------------------------------------
    def self.decode(token)
      decoded = JWT.decode(
        token,
        JwtConfig::SECRET_KEY,
        true,
        { algorithm: JwtConfig::ALGORITHM }
      )
      decoded.first.with_indifferent_access
    rescue JWT::ExpiredSignature
      raise Errors::TokenExpired, "Access token has expired"
    rescue JWT::DecodeError => e
      raise Errors::InvalidToken, "Invalid token: #{e.message}"
    end

    # -------------------------------------------------------
    # Encode a refresh token (long-lived)
    # -------------------------------------------------------
    def self.encode_refresh(payload)
      payload = payload.dup
      payload[:exp] = JwtConfig::REFRESH_EXPIRY.from_now.to_i
      payload[:iat] = Time.current.to_i
      payload[:type] = "refresh"
      JWT.encode(payload, JwtConfig::REFRESH_SECRET_KEY, JwtConfig::ALGORITHM)
    end

    # -------------------------------------------------------
    # Decode and verify a refresh token
    # -------------------------------------------------------
    def self.decode_refresh(token)
      decoded = JWT.decode(
        token,
        JwtConfig::REFRESH_SECRET_KEY,
        true,
        { algorithm: JwtConfig::ALGORITHM }
      )
      payload = decoded.first.with_indifferent_access
      raise Errors::InvalidToken, "Not a refresh token" unless payload[:type] == "refresh"
      payload
    rescue JWT::ExpiredSignature
      raise Errors::TokenExpired, "Refresh token has expired"
    rescue JWT::DecodeError => e
      raise Errors::InvalidToken, "Invalid token: #{e.message}"
    end

    # -------------------------------------------------------
    # Generate a token pair (access + refresh)
    # -------------------------------------------------------
    def self.issue_token_pair(user, device_uid: nil)
      payload = {
        user_id:    user.id,
        username:   user.username,
        is_guest:   user.is_guest,
        device_uid: device_uid
      }
      raw_refresh = SecureRandom.hex(64)
      token_hash  = Digest::SHA256.hexdigest(raw_refresh)

      refresh_record = user.refresh_tokens.create!(
        token_hash: token_hash,
        expires_at: JwtConfig::REFRESH_EXPIRY.from_now,
        device_uid: device_uid
      )

      {
        access_token:  encode(payload),
        refresh_token: raw_refresh,
        expires_in:    JwtConfig::ACCESS_EXPIRY.to_i
      }
    end
  end
end
