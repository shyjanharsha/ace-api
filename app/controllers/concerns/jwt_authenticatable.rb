module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  # Call this in any controller action requiring authentication
  def authenticate_user!
    token = extract_token_from_header
    raise Errors::InvalidToken, "Authorization token missing" if token.blank?

    payload = Auth::JwtService.decode(token)
    @current_user = User.find(payload[:user_id])
  rescue ActiveRecord::RecordNotFound
    raise Errors::Unauthorized, "User not found"
  end

  # Non-strict version — sets current_user if token present, but doesn't fail
  def authenticate_user_optional
    token = extract_token_from_header
    return if token.blank?

    payload = Auth::JwtService.decode(token)
    @current_user = User.find_by(id: payload[:user_id])
  rescue Errors::Base
    @current_user = nil
  end

  private

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil if auth_header.blank?
    auth_header.split(" ").last
  end
end
