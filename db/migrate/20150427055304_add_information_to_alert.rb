class AddInformationToAlert < ActiveRecord::Migration
  def change
    add_column :alerts, :information, :text
  end
end
