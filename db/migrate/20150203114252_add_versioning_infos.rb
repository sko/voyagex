class AddVersioningInfos < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :user_id
      t.string :hash
      t.datetime :timestamp
      t.integer :local_time_millis
    end
    add_index :commits, :hash
    add_index :commits, :timestamp

    add_column :locations, :commit_hash, :string, nil: false
    add_column :locations, :local_time_millis, :integer
    add_column :pois, :commit_hash, :string, nil: false
    add_column :pois, :local_time_millis, :integer
    add_column :poi_notes, :commit_hash, :string, nil: false
    add_column :poi_notes, :local_time_millis, :integer
  end
end
