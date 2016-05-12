class AddRepositoryFolderToUsers < ActiveRecord::Migration
  def change
    add_column :users, :repository_folder, :string
  end
end
