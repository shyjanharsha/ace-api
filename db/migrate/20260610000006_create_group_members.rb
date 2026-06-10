class CreateGroupMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :group_members do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.string     :role,  null: false, default: "member"
      # role: admin | member
      t.datetime   :joined_at, null: false, default: -> { "NOW()" }

      t.timestamps
    end

    add_index :group_members, [:group_id, :user_id], unique: true
    add_index :group_members, :role
  end
end
