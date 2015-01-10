class AddUserSnapshots < ActiveRecord::Migration
  def change
    create_table :user_snapshots do |t|
      t.integer :user_id
      t.integer :location_id
      t.float :lat
      t.float :lng
      t.string :address
      t.string :cur_commit_hash
      t.timestamps
    end
    add_index :user_snapshots, :user_id

    add_column :comm_peers, :note_follower, :text
    add_column :comm_peers, :note_followed, :text
  end
end
