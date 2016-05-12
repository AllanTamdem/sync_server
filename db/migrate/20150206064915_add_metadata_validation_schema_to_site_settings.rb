class AddMetadataValidationSchemaToSiteSettings < ActiveRecord::Migration
  def change
    add_column :site_settings, :metadata_validation_schema, :text
  end
end