class AnalyticsFileType

  include Mongoid::Document

  field :file, type: String
  field :type, type: String

  index({ file: 1 }, { unique: true })

end

# To create the indexes:
# rake db:mongoid:create_indexes