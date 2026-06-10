# Puma configuration — optimized for production WebSocket + REST workload
#
# WEB_CONCURRENCY: number of worker processes (set to CPU core count)
# RAILS_MAX_THREADS: threads per worker (Puma is multi-threaded)
#
# For ActionCable with many concurrent WebSocket connections,
# increase WEB_CONCURRENCY and use a Unix socket for Nginx.

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

# Worker processes (set in production, keep 0 in dev for code reloading)
workers ENV.fetch("WEB_CONCURRENCY", 2).to_i

# Use Unix socket in production for Nginx proxy (faster than TCP)
if ENV["RAILS_ENV"] == "production"
  bind "unix:///rails/tmp/sockets/puma.sock"
else
  port ENV.fetch("PORT", 3000)
end

# Worker timeout — kill workers that take > 60s (prevents hangs)
worker_timeout 60

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Preload app for faster worker forking (copy-on-write friendly)
preload_app!

on_worker_boot do
  # Reconnect to DB and Redis after fork
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Graceful shutdown — wait for in-flight requests
on_worker_shutdown do
  Rails.logger.info "Puma worker shutting down gracefully"
end
