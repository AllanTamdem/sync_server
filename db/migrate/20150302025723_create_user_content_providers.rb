class CreateUserContentProviders < ActiveRecord::Migration
  def change
    create_table :user_content_providers do |t|
      t.integer :user_id
      t.integer :content_provider_id

      t.timestamps
    end
  end
end
