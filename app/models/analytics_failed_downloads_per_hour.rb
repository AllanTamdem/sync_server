class AnalyticsFailedDownloadsPerHour

  include Mongoid::Document

  field :mediaspot_id, type: String
  field :client_name, type: String
  field :time, type: DateTime
  field :num_failures, type: Integer



  index({ mediaspot_id: 1 })
  index({ client_name: 1, mediaspot_id: 1 })

end

# To create the indexes:
# rake db:mongoid:create_indexes