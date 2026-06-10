module Api
  module V1
    class GameController < ApplicationController
      before_action :authenticate_user!
      before_action :set_match

      # POST /api/v1/game/:match_id/play
      # Body: { card_code: "AS", move_seq: 5 }
      def play
        GameEngine::TurnManager.new(
          match:     @match,
          player_id: current_user.id,
          card_code: params.require(:card_code),
          move_seq:  params[:move_seq]
        ).execute!

        render_success({ played: true, card: params[:card_code] })
      end

      # POST /api/v1/game/:match_id/reconnect
      def reconnect
        mp = @match.match_players.find_by(user_id: current_user.id)
        raise Errors::Forbidden, "You are not in this match" unless mp

        GameEngine::ReconnectHandler.new(@match, current_user).restore!
        render_success({ reconnected: true, message: "State restored via WebSocket" })
      end

      private

      def set_match
        @match = Match.find(params[:match_id])
        raise Errors::NotFound, "Match not found" unless @match
        raise Errors::UnprocessableEntity, "Match is not active" unless @match.status == "active"
      end
    end
  end
end
