class CreateSiteSettings < ActiveRecord::Migration
  def change
    create_table :site_settings do |t|
      t.text :metadata_template

      t.timestamps
    end
  end
end
