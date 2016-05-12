class AddSmsNotificationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :sms_subscribed_alert_mediaspot_offline, :boolean, :default => false
    add_column :users, :sms_subscribed_alert_sync_error, :boolean, :default => false
  end
end
