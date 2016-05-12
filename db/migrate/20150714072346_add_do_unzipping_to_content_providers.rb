class AddDoUnzippingToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :do_unzipping, :boolean, default: false
  end
end
