class RepoController < ApplicationController
	
	before_action :authenticate_user!

	include SiteSettingsHelper
	include UsersHelper

	def index

		user_content_providers = user_get_content_providers(current_user)

		@content_providers = []

		if current_user.admin == true
			@content_providers << {technical_name: '/', name: 'All files (on the default bucket)'}
		end

		user_content_providers.each{ |cp|
			@content_providers << {technical_name: cp.technical_name, name: cp.name}
		}


		@metadata_template = sites_settings_metadata_template
	end
	
end