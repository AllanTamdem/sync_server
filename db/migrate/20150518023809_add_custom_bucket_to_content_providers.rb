class AddCustomBucketToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :aws_bucket_access_key_id, :string
    add_column :content_providers, :aws_bucket_secret_access_key, :string
    add_column :content_providers, :aws_bucket_region, :string
    add_column :content_providers, :aws_bucket_name, :string
  end
end
