class CreateGameMoves < ActiveRecord::Migration[7.1]
  def change
    create_table :game_moves do |t|
      t.references :match,        null: false, foreign_key: true
      t.references :player,       null: false, foreign_key: { to_table: :users }
      t.integer    :round_number, null: false, default: 1
      t.integer    :trick_number, null: false, default: 0
      t.integer    :move_seq,     null: false              # sequence within match
      t.string     :card_played,  null: false              # e.g. "AS", "KH", "7C"
      t.string     :move_type,    null: false, default: "play"
      # move_type: play | auto_play | timeout_skip
      t.boolean    :is_cut,       default: false, null: false
      t.boolean    :won_trick,    default: false, null: false
      t.datetime   :played_at,    null: false

      t.timestamps
    end

    add_index :game_moves, [:match_id, :trick_number]
    add_index :game_moves, [:match_id, :move_seq], unique: true
    add_index :game_moves, :played_at
    add_index :game_moves, :is_cut
  end
end
