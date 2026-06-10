class CreateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :invitations do |t|
      t.references :sender,    null: false, foreign_key: { to_table: :users }
      t.references :receiver,  null: false, foreign_key: { to_table: :users }
      t.references :room,      null: false, foreign_key: { to_table: :game_rooms }
      t.string     :status,    null: false, default: "pending"
      # status: pending | accepted | declined | expired | cancelled
      t.datetime   :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, [:sender_id, :receiver_id, :room_id], unique: true
    add_index :invitations, :status
    add_index :invitations, :expires_at
  end
end
