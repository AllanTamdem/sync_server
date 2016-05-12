class Repo2Controller < ApplicationController
	
	before_action :authenticate_user!

	include SiteSettingsHelper
	include ContentProvidersHelper
	include UsersHelper

	def index

		# if current_user.admin == true

		# 	default_bucket = get_default_s3_info[:aws_bucket_name]
			
		# 	@buckets = get_all_buckets

		# 	@selected_bucket = params[:bucket]

		# 	if @selected_bucket.blank?
		# 		@selected_bucket = default_bucket
		# 	end

		# 	@s3_info = find_s3_info_by_bucket_name(@selected_bucket)

		# 	@path_prefix = ''

		# else

		@content_providers = user_get_content_providers(current_user)

		if current_user.admin == true

			@content_providers.unshift({id: 0, name: 'All files (on the default bucket)'})

		end


		selected_content_provider_id = params[:content_provider].to_i

		@selected_content_provider = @content_providers.find{|cp| cp[:id] == selected_content_provider_id } || @content_providers.first

		@selected_content_provider_id = @selected_content_provider[:id]

		if @selected_content_provider_id == 0

			@s3_info = get_default_s3_info
			@path_prefix = ''

		else

			@s3_info = get_s3_info_from_content_provider(@selected_content_provider)
			@path_prefix = path_prettify(@selected_content_provider.path_in_bucket)

			if @selected_content_provider.path_in_bucket.blank?
				@path_prefix = path_prettify(@selected_content_provider.technical_name)
			else
				@path_prefix = path_prettify(@selected_content_provider.path_in_bucket)
			end

		end

		if @s3_info[:aws_bucket_name].blank?
			@s3_info = get_default_s3_info
		end
		
		@metadata_template = sites_settings_metadata_template

	end


	private

		def get_all_buckets

			default_bucket = get_default_s3_info[:aws_bucket_name]
			
			buckets = [{
				bucket: default_bucket,
				text: default_bucket + ' (default)'
			}]

			ContentProvider.all.each{ |cp|
				if cp[:aws_bucket_name].blank? == false  and 
					buckets.none?{|b| b[:bucket] == cp[:aws_bucket_name]}

					buckets << {
						bucket: cp[:aws_bucket_name],
						text: cp[:aws_bucket_name]
					}
				end
			}

			return buckets

		end

	
end