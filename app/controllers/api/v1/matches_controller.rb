module Api
  module V1
    class MatchesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/matches/:id
      def show
        match = Match.includes(:match_players, :game_room).find(params[:id])
        render_success(match_payload(match))
      end

      # GET /api/v1/matches/:id/replay
      def replay
        match = Match.find(params[:id])
        moves = match.game_moves.includes(:player).ordered.map do |m|
          {
            seq:         m.move_seq,
            player_id:   m.player_id,
            username:    m.player.username,
            card:        m.card_played,
            move_type:   m.move_type,
            trick:       m.trick_number,
            is_cut:      m.is_cut,
            won_trick:   m.won_trick,
            played_at:   m.played_at.iso8601
          }
        end

        render_success({
          match_id:    match.id,
          total_moves: moves.size,
          moves:       moves
        })
      end

      private

      def match_payload(match)
        {
          id:          match.id,
          status:      match.status,
          started_at:  match.started_at&.iso8601,
          ended_at:    match.ended_at&.iso8601,
          duration_s:  match.duration_seconds,
          room:        { id: match.game_room.id, code: match.game_room.code },
          winner_id:   match.winner_id,
          players:     match.match_players.map { |mp|
            {
              user_id:      mp.user_id,
              seat_position: mp.seat_position,
              is_donkey:    mp.is_donkey,
              final_rank:   mp.final_rank,
              tricks_won:   mp.tricks_won,
              coins_won:    mp.coins_won
            }
          }
        }
      end
    end
  end
end
