module ContentProvidersHelper

	include PathHelper


	def get_default_s3_info

		return {
				aws_bucket_access_key_id: Rails.configuration.aws_access_key_id,
				aws_bucket_secret_access_key: Rails.configuration.aws_secret_access_key,
				aws_bucket_region: Rails.configuration.aws_region,
				aws_bucket_name: Rails.configuration.aws_bucket,
				aws_bucket_host: get_s3_hostname_by_region(Rails.configuration.aws_region)
			}
	end


	def get_content_provider_by_technical_name technical_name

		cp = ContentProvider.select{ |c|
			path_prettify(technical_name) == path_prettify(c[:technical_name])
		}.first

		return cp

	end


	def get_content_provider_s3_info name

		if (name.blank? or name.strip == '/') == false

			cp = ContentProvider.select{ |c|
				path_prettify(name) == path_prettify(c[:technical_name])
			}.first

			if cp != nil and cp[:aws_bucket_name].blank? == false

				return get_s3_info_from_content_provider(cp)

			end

		end

		return get_default_s3_info

	end


	def get_all_s3_infos

		s3_infos = [get_default_s3_info]

		ContentProvider.all.each{ |cp|

			if false == (cp[:aws_bucket_access_key_id].blank? or
				cp[:aws_bucket_secret_access_key].blank? or
				cp[:aws_bucket_region].blank? or
				cp[:aws_bucket_name].blank?)

				if s3_infos.none?{|s3| (s3[:aws_bucket_name].to_s == cp[:aws_bucket_name].to_s && s3[:path_in_bucket].to_s == cp[:path_in_bucket].to_s )}

					s3_info = get_s3_info_from_content_provider(cp)

					s3_info[:path_in_bucket] = cp[:path_in_bucket]

					s3_infos << s3_info

				end

			end

		}

		s3_infos

	end

	def find_s3_info_by_bucket_name bucket_name

		default_s3_info = get_default_s3_info

		if bucket_name.blank?
			return default_s3_info
		end

		if default_s3_info[:aws_bucket_name] == bucket_name
			return default_s3_info
		end

		ContentProvider.all.each{ |cp|
			if bucket_name == cp[:aws_bucket_name] 
				return  get_s3_info_from_content_provider(cp)
			end
		}

		return default_s3_info

	end

	def get_s3_info_from_content_provider content_provider
		return  {
			aws_bucket_access_key_id: content_provider[:aws_bucket_access_key_id],
			aws_bucket_secret_access_key: content_provider[:aws_bucket_secret_access_key],
			aws_bucket_region: content_provider[:aws_bucket_region],
			aws_bucket_name: content_provider[:aws_bucket_name],
			aws_bucket_host: get_s3_hostname_by_region(content_provider[:aws_bucket_region])
		}
	end


	# returns the content providers that matches a file
	def find_content_providers_by_bucket_and_file bucket, file_key
		content_providers = []

		default_s3_info = get_default_s3_info

		ContentProvider.all.each{ |cp|
			cp_bucket = cp[:aws_bucket_name]
			if cp_bucket.blank?
				cp_bucket = default_s3_info[:aws_bucket_name]
			end

			if cp_bucket == bucket

				cp_path_in_bucket = cp[:path_in_bucket]
				if cp_path_in_bucket.blank?
					cp_path_in_bucket = cp[:technical_name]
				end

				path_in_bucket = path_prettify(cp_path_in_bucket)

				if file_key.start_with?(path_in_bucket) ||
					file_key.start_with?(path_in_bucket.gsub(' ','+')) ||
					file_key.start_with?(path_in_bucket.gsub(' ','%20'))
					
					content_providers << cp
				end

			end
		}

		content_providers
	end


	private

		def get_s3_hostname_by_region region
			if !Rails.configuration.aws_endpoint.nil? #fake S3
				return " #{Rails.configuration.aws_endpoint}"
			end

			if region == 'us-east-1'
				return ' https://s3.amazonaws.com'
			else
				return " https://s3-#{region}.amazonaws.com"
			end
		end


end