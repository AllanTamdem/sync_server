class CreateContentProviders < ActiveRecord::Migration
  def change
    create_table :content_providers do |t|
      t.string :name
      t.text :description
      t.string :repository_folder
      t.string :mediaspot_client_name

      t.timestamps
    end
  end
end
