module SiteSettingsHelper


	def sites_settings_metadata_template
	  	get_settings[:metadata_template]
	end

	def sites_settings_metadata_validation_schema
	  	get_settings[:metadata_validation_schema]
	end

	def sites_settings_tr069_hosts_white_list
	  	get_settings[:tr069_hosts_white_list]
	end

	def sites_settings_websocket_hosts_white_list
	  	get_settings[:websocket_hosts_white_list]
	end

	def sites_settings_super_admins
	  	(get_settings[:super_admins] || '[]').split(',').map{|e| e.strip}
	end

	private
		def get_settings
  		settings = SiteSettings.first
	  	if settings == nil
				settings = SiteSettings.new(metadata_template: '[]', super_admins: '[]', metadata_validation_schema: nil)
	  	end
	  	settings
		end
end


