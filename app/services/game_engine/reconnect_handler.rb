module GameEngine
  # Restores private game state to a reconnecting player
  class ReconnectHandler
    def initialize(match, user)
      @match = match
      @user  = user
      @state = match.game_state
    end

    def restore!
      hand         = @state.dig("hands", @user.id.to_s) || []
      leading_suit = @state["leading_suit"]
      trick_pile   = @state["trick_pile"] || []
      is_my_turn   = @state["current_turn"].to_s == @user.id.to_s

      # Send private hand (only to this player's private stream)
      ActionCable.server.broadcast(
        "game_#{@match.id}_player_#{@user.id}",
        {
          type: "reconnected_state",
          data: {
            hand:            hand,
            hand_count:      hand.size,
            leading_suit:    leading_suit,
            trick_pile:      trick_pile,
            is_my_turn:      is_my_turn,
            current_trick:   @state["current_trick"],
            active_players:  @state["active_players"],
            move_seq:        @state["move_seq"],
            timeout_seconds: @match.game_room.move_timeout
          }
        }
      )

      # Also send current game summary to public stream for UI sync
      ActionCable.server.broadcast("game_#{@match.id}", {
        type: "player_reconnected",
        data: {
          user_id:  @user.id,
          username: @user.username,
          hand_count: hand.size  # card count only, not the actual cards
        }
      })
    end
  end
end
