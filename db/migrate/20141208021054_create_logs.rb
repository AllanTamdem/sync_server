class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :interface
      t.string :user_ip
      t.text :user
      t.string :action_type
      t.text :content

      t.timestamps
    end
  end
end

