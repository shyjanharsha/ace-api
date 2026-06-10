# Rack::Attack — Rate limiting & anti-cheat protection
# Throttle rules are enforced before Rails routing.

class Rack::Attack
  # -------------------------------------------------------
  # Throttle: Global API calls per IP
  # -------------------------------------------------------
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/cable")
  end

  # -------------------------------------------------------
  # Throttle: Auth endpoints (prevent brute force)
  # -------------------------------------------------------
  throttle("logins/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  throttle("signups/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/signup" && req.post?
  end

  throttle("otp/phone", limit: 5, period: 15.minutes) do |req|
    if req.path.start_with?("/api/v1/auth/otp") && req.post?
      body = JSON.parse(req.body.read) rescue {}
      req.body.rewind
      body["phone"]
    end
  end

  # -------------------------------------------------------
  # Throttle: Game moves (anti-cheat — max 1 move per 500ms)
  # -------------------------------------------------------
  throttle("game_moves/user", limit: 2, period: 1.second) do |req|
    if req.path.match?(%r{/api/v1/game/\d+/play}) && req.post?
      req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
    end
  end

  # -------------------------------------------------------
  # Throttle: Contact sync (expensive operation)
  # -------------------------------------------------------
  throttle("contact_sync/ip", limit: 3, period: 10.minutes) do |req|
    req.ip if req.path == "/api/v1/contacts/sync" && req.post?
  end

  # -------------------------------------------------------
  # Response for throttled requests
  # -------------------------------------------------------
  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Too many requests. Please slow down.", retry_after: retry_after }.to_json]
    ]
  end
end
