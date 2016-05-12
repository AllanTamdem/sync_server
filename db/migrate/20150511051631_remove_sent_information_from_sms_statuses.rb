class RemoveSentInformationFromSmsStatuses < ActiveRecord::Migration

  def up
    remove_column :sms_statuses, :sent_information
  end

  def down
    add_column :sms_statuses, :sent_information, :text
  end
end
