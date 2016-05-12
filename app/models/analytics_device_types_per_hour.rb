class AnalyticsDeviceTypesPerHour

  include Mongoid::Document

  field :mediaspot_id, type: String
  field :mediaspot_name, type: String
  field :client_name, type: String
  field :device_type, type: String
  field :time, type: DateTime
  field :accesses, type: Integer



  index({ client_name: 1, mediaspot_id: 1 })
  index({ client_name: 1, mediaspot_id: 1, time: 1 })
  index({ client_name: 1 })
  index({ client_name: 1, time: 1  })

end

# To create the indexes:
# rake db:mongoid:create_indexes