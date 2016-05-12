class AddSuperAdminsToSiteSettings < ActiveRecord::Migration
  def change
    add_column :site_settings, :super_admins, :text
  end
end
