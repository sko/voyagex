class AddVersioningInfos < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :user_id
      t.string :hash_id
      t.datetime :timestamp
      t.integer :local_time_secs
    end
    add_index :commits, :hash_id
    add_index :commits, :timestamp
    remove_column :user_snapshots, :cur_commit_hash, :string
    add_column :user_snapshots, :commit_id, :integer

    add_column :locations, :commit_hash, :string, nil: false
    add_column :locations, :local_time_secs, :integer
    add_column :pois, :commit_hash, :string, nil: false
    add_column :pois, :local_time_secs, :integer
    add_column :poi_notes, :commit_hash, :string, nil: false
    add_column :poi_notes, :local_time_secs, :integer
  end
end
