class AddHostsWhiteListsToSiteSettings < ActiveRecord::Migration
  def change
    add_column :site_settings, :tr069_hosts_white_list, :text
    add_column :site_settings, :websocket_hosts_white_list, :text
  end
end
