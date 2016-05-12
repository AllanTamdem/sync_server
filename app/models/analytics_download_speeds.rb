class AnalyticsDownloadSpeeds

  include Mongoid::Document

  field :mediaspot_id, type: String
  field :client_name, type: String
  field :download_speeds, type: String

  index({ mediaspot_id: 1 })
  index({ client_name: 1 })

end

# To create the indexes:
# rake db:mongoid:create_indexes