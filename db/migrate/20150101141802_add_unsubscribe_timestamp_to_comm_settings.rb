class AddUnsubscribeTimestampToCommSettings < ActiveRecord::Migration
  def change
    add_column :comm_settings, :unsubscribe_ts, :datetime
  end
end
