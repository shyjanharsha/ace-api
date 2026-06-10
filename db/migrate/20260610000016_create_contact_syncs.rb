class CreateContactSyncs < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_syncs do |t|
      t.references :user,           null: false, foreign_key: true
      t.string     :phone_hash,     null: false  # SHA256 of normalized phone number
      t.references :matched_user,   null: true,  foreign_key: { to_table: :users }
      # matched_user_id: set if a user with this phone hash exists

      t.timestamps
    end

    # Prevent duplicate contact entries per user
    add_index :contact_syncs, [:user_id, :phone_hash], unique: true
    add_index :contact_syncs, :phone_hash
  end
end
