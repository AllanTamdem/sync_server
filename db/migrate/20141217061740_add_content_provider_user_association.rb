class AddContentProviderUserAssociation < ActiveRecord::Migration
  def change
  	add_column :users, :content_provider_id, :integer
  	add_foreign_key :users, :content_providers
  end
end