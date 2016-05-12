class CreateAlert < ActiveRecord::Migration

  def change

    create_table :alerts do |t|

      t.string :type_alert, null: false

      t.string :last_sent_to
      t.datetime :last_sent_at
      t.integer :sent_count
      t.datetime :resolved_at

      t.string :mediaspot_id
      t.string :mediaspot_name
      t.string :mediaspot_client_name
      t.string :mediaspot_client_number

      t.timestamps

    end
  end
end