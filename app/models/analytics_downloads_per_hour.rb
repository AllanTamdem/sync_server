class AnalyticsDownloadsPerHour

  include Mongoid::Document

  field :mediaspot_id, type: String
  field :mediaspot_name, type: String
  field :client_name, type: String
  field :file, type: String
  field :size, type: Integer
  field :time, type: DateTime
  field :file_type, type: String
  field :bytes, type: Integer



  index({ client_name: 1, mediaspot_id: 1 })
  index({ client_name: 1, mediaspot_id: 1, time: 1 })
  index({ client_name: 1 })
  index({ client_name: 1, time: 1  })

end

# To create the indexes:
# rake db:mongoid:create_indexes