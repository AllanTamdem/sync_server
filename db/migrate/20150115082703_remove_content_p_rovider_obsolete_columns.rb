class RemoveContentPRoviderObsoleteColumns < ActiveRecord::Migration
  def change
  	remove_column :content_providers, :repository_folder, :string
  	remove_column :content_providers, :mediaspot_client_name, :string
  end
end