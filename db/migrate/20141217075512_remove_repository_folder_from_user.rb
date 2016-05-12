class RemoveRepositoryFolderFromUser < ActiveRecord::Migration
  def change
  	remove_column :users, :repository_folder, :string
  end
end
