class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.references :owner,      null: false, foreign_key: { to_table: :users }
      t.string     :name,       null: false
      t.text       :description
      t.string     :avatar_url
      t.string     :group_type, null: false, default: "private"
      # group_type: public | private
      t.string     :invite_code            # shareable invite code

      t.timestamps
    end

    add_index :groups, :invite_code, unique: true, where: "invite_code IS NOT NULL"
    add_index :groups, :group_type
  end
end
