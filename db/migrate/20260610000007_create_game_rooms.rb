class CreateGameRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :game_rooms do |t|
      t.references :host,       null: false, foreign_key: { to_table: :users }
      t.string     :code,       null: false              # unique 6-char join code
      t.string     :status,     null: false, default: "waiting"
      # status: waiting | playing | finished | cancelled
      t.string     :room_type,  null: false, default: "public"
      # room_type: public | private
      t.integer    :max_players, null: false, default: 4  # 2–8
      t.integer    :min_players, null: false, default: 2
      t.integer    :bet_coins,   null: false, default: 0  # 0 = no bet
      t.jsonb      :config,      null: false, default: {}
      # config: { move_timeout_seconds: 30, allow_spectators: false }

      t.timestamps
    end

    add_index :game_rooms, :code, unique: true
    add_index :game_rooms, :status
    add_index :game_rooms, :room_type
    add_index :game_rooms, :config, using: :gin
  end
end
