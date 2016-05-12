class ApplicationLog

	Action_type_tr069 = 'TR069'
	Action_type_repo = 'FILE_REPO'
	Action_type_profile = 'PROFILE'
	Action_type_users = 'USERS'
	Action_type_content_providers = 'CONTENT_PROVIDERS'
	Action_type_site_settings = 'SITE_SETTINGS'

  include Mongoid::Document

  field :time, type: DateTime
  field :user, type: String
  field :action_type, type: String
  field :action, type: String
  field :details, type: String

  index({ time: 1 })
end

# To create the indexes:
# rake db:mongoid:create_indexes