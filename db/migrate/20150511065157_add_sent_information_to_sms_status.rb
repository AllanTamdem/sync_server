class AddSentInformationToSmsStatus < ActiveRecord::Migration
  def change
    add_column :sms_statuses, :sent_information, :text
  end
end
