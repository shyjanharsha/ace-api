REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

$redis = Redis.new(url: REDIS_URL, timeout: 1.0)

# Connection pool for multi-threaded environments
REDIS_POOL = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i + 2, timeout: 5) do
  Redis.new(url: REDIS_URL, timeout: 1.0)
end
