class RemoveContentProviderIdFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :content_provider_id
  end

  def down
    add_column :users, :content_provider_id, :integer
  end
end
