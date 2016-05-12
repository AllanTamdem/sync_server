class AddPathInBucketToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :path_in_bucket, :string
  end
end
