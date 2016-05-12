class AddTechnicalNameToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :technical_name, :string
  end
end
