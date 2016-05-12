class AddSubscribedAlertMediaspotOfflineToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscribed_alert_mediaspot_offline, :boolean, :default => false
  end
end
