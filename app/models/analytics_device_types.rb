class AnalyticsDeviceTypes

  include Mongoid::Document

  field :mediaspot_id, type: String
  field :client_name, type: String
  field :device_type, type: String
  field :downloads, type: Integer  

  index({ mediaspot_id: 1 })
  index({ client_name: 1 })
  index({ device_type: 1 })

end

# To create the indexes:
# rake db:mongoid:create_indexes