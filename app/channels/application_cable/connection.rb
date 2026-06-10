module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      Rails.logger.info "[ActionCable] User #{current_user.id} (#{current_user.username}) connected"
    end

    def disconnect
      Rails.logger.info "[ActionCable] User #{current_user&.id} disconnected"
    end

    private

    def find_verified_user
      # Token passed as query param: ws://host/cable?token=<jwt>
      token = request.params[:token]

      if token.blank?
        # Also try Authorization header for compatibility
        token = request.headers["Authorization"]&.split(" ")&.last
      end

      raise ActionCable::Connection::Authorization::UnauthorizedError if token.blank?

      begin
        payload = Auth::JwtService.decode(token)
        user    = User.find(payload[:user_id])
        raise ActionCable::Connection::Authorization::UnauthorizedError unless user
        user
      rescue Errors::Base, ActiveRecord::RecordNotFound
        reject_unauthorized_connection
      end
    end
  end
end
