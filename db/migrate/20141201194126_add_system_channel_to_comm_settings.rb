class AddSystemChannelToCommSettings < ActiveRecord::Migration
  def change
    add_column :comm_settings, :sys_channel_enc_key, :string
    add_column :users, :home_base_id, :integer
    add_column :users, :search_radius_meters, :integer
  end
end
