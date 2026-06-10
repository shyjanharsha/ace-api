class CreateFriendships < ActiveRecord::Migration[7.1]
  def change
    create_table :friendships do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :receiver,  null: false, foreign_key: { to_table: :users }
      t.string     :status,    null: false, default: "pending"
      # status: pending | accepted | blocked | declined

      t.timestamps
    end

    # Prevent duplicate friendship rows — A→B and A→B not allowed
    add_index :friendships, [:requester_id, :receiver_id], unique: true
    add_index :friendships, :status
  end
end
