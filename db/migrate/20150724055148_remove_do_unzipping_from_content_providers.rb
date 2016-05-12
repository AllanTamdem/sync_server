class RemoveDoUnzippingFromContentProviders < ActiveRecord::Migration
  def change
    remove_column :content_providers, :do_unzipping, :boolean, default: false
  end
end
