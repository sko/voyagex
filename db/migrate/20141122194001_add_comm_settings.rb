class AddCommSettings < ActiveRecord::Migration
  def change
    create_table :comm_settings do |t|
      t.integer :user_id, null: false
      t.string :channel_enc_key, null: false

      t.timestamps
    end
    add_index :comm_settings, :user_id
    add_index :comm_settings, :channel_enc_key
    
    create_table :comm_peers do |t|
      t.integer :comm_setting_id, null: false
      t.integer :peer_id, null: false

      t.timestamps
    end
    add_index :comm_peers, :comm_setting_id
  end
end
