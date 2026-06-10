class ApplicationController < ActionController::API
  include JwtAuthenticatable
  include Pagy::Backend

  # -------------------------------------------------------
  # Global error handling
  # -------------------------------------------------------
  rescue_from Errors::InvalidToken,        with: :render_unauthorized
  rescue_from Errors::TokenExpired,        with: :render_token_expired
  rescue_from Errors::Unauthorized,        with: :render_unauthorized
  rescue_from Errors::Forbidden,           with: :render_forbidden
  rescue_from Errors::NotFound,            with: :render_not_found
  rescue_from Errors::UnprocessableEntity, with: :render_unprocessable
  rescue_from Errors::InvalidMove,         with: :render_game_error
  rescue_from Errors::NotYourTurn,         with: :render_game_error
  rescue_from Errors::InsufficientCoins,   with: :render_unprocessable
  rescue_from Errors::RoomFull,            with: :render_unprocessable
  rescue_from Errors::RoomClosed,          with: :render_unprocessable
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def render_success(data, status: :ok, meta: nil)
    response_body = { success: true, data: data }
    response_body[:meta] = meta if meta
    render json: response_body, status: status
  end

  def render_created(data)
    render_success(data, status: :created)
  end

  def render_error(message, status:, code: nil)
    render json: { success: false, error: message, code: code }, status: status
  end

  def render_unauthorized(error = nil)
    render_error(error&.message || "Unauthorized", status: :unauthorized, code: "UNAUTHORIZED")
  end

  def render_token_expired(error = nil)
    render_error("Token has expired", status: :unauthorized, code: "TOKEN_EXPIRED")
  end

  def render_forbidden(error = nil)
    render_error(error&.message || "Forbidden", status: :forbidden, code: "FORBIDDEN")
  end

  def render_not_found(error = nil)
    render_error(error&.message || "Resource not found", status: :not_found, code: "NOT_FOUND")
  end

  def render_unprocessable(error = nil)
    render_error(error&.message || "Unprocessable entity", status: :unprocessable_entity, code: "UNPROCESSABLE")
  end

  def render_game_error(error)
    render_error(error.message, status: :unprocessable_entity, code: "GAME_ERROR")
  end

  def render_bad_request(error)
    render_error(error.message, status: :bad_request, code: "BAD_REQUEST")
  end

  def pagy_meta(pagy)
    {
      current_page:  pagy.page,
      total_pages:   pagy.pages,
      total_count:   pagy.count,
      per_page:      pagy.items,
      next_page:     pagy.next,
      prev_page:     pagy.prev
    }
  end
end
