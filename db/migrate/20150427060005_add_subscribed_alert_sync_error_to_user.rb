class AddSubscribedAlertSyncErrorToUser < ActiveRecord::Migration
  def change
    add_column :users, :subscribed_alert_sync_error, :boolean, :default => false
  end
end
