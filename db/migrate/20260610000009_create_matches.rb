class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :game_room,     null: false, foreign_key: true
      t.references :winner,        null: true,  foreign_key: { to_table: :users }
      t.string     :status,        null: false, default: "active"
      # status: active | completed | abandoned
      t.integer    :current_trick, null: false, default: 0
      t.integer    :current_round, null: false, default: 1
      t.datetime   :started_at
      t.datetime   :ended_at
      t.jsonb      :game_state,    null: false, default: {}
      # Canonical server state: { hands: {player_id: [cards]}, trick_pile: [...],
      #   current_turn: player_id, leading_suit: "spades", trick_leader: player_id,
      #   active_players: [player_ids], finished_players: [player_ids],
      #   move_seq: int }
      t.jsonb      :replay_data,   null: false, default: []
      # Append-only array of all moves for replay feature

      t.timestamps
    end

    add_index :matches, :status
    add_index :matches, :game_state, using: :gin
  end
end
