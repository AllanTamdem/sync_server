# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!


Rails.logger = Le.new(Rails.configuration.logentries_token, local: true)
Mongoid.logger = Le.new(Rails.configuration.logentries_token, local: true)