class AddUnzippingFilesToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :unzipping_files, :string
  end
end
