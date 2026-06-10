module JwtConfig
  SECRET_KEY         = ENV.fetch("JWT_SECRET_KEY") { raise "JWT_SECRET_KEY is not set!" }
  REFRESH_SECRET_KEY = ENV.fetch("JWT_REFRESH_SECRET") { raise "JWT_REFRESH_SECRET is not set!" }
  ALGORITHM          = "HS256"
  ACCESS_EXPIRY      = ENV.fetch("JWT_ACCESS_EXPIRY_HOURS", "24").to_i.hours
  REFRESH_EXPIRY     = ENV.fetch("JWT_REFRESH_EXPIRY_DAYS", "30").to_i.days
end
