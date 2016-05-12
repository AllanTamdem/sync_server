class CreateSmsStatus < ActiveRecord::Migration
  def change
    create_table :sms_statuses do |t|

      t.string :sms_id
      t.text :sent_information
      t.text :status_information
      
      t.timestamps

    end

    add_index :sms_statuses, :sms_id
  end
end