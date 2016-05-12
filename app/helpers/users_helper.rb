module UsersHelper

	include PathHelper
	include ContentProvidersHelper

	# 
	# FILE REPOSITORY STUFF
	# 

	# check that the s3_key starts with the path in user.content_provider.technical_name
	def user_has_access? user, s3_key

		if user.admin == true
			return true
		end

		repository_folders = user_get_repository_folders(user)

		ret = repository_folders.any?{ |folder|
			user_path = path_prettify(folder)
			start_key = path_prettify(s3_key[0..((user_path).length - 1)])

			user_path == start_key
		}

		return ret
	end



	def user_has_s3_access? user, bucket, paths

		if user.admin == true
			return true
		end

		user_content_providers = user.content_providers
		default_aws_bucket_name = get_default_s3_info[:aws_bucket_name]


		has_access_to_all = paths.all?{ |path|

			has_access = false

			user_content_providers.each{ |cp|

				cp_bucket_name = cp.aws_bucket_name

				if cp_bucket_name.blank?
					cp_bucket_name = default_aws_bucket_name
				end

				if cp_bucket_name == bucket
					if path.starts_with?(path_prettify(cp.path_in_bucket.blank? ? cp.technical_name : cp.path_in_bucket))
						has_access = true
					end
				end
			}

			has_access
		}

		return has_access_to_all

	end



	def user_get_repository_folders user
		user_get_content_providers(user).map{ |f|
			path_prettify(f.path_in_bucket.blank? ? f.technical_name : f.path_in_bucket)
		}
	end

	def user_get_content_providers user
		if user.admin == true
			return ContentProvider.order(:name)
		else
			return user.content_providers || []
		end
	end

	# 
	# MEDIASPOT STUFF
	# 

	# check that the user has access to this client on the mediaspot
	def user_can_see_client? user, client_name
		if user.admin == true
			return true
		else
			return user_get_mediaspot_client_names(user).any?{ |name|
				name == client_name
			}
		end
	end

	def user_get_mediaspot_client_names user
		return (user.content_providers || []).map{ |f|
			f.technical_name
		}
	end

	# get the users who belongs to a content provider
	def get_users_per_client_names client_names, user_filter
		users = []
		ContentProvider.where(technical_name: client_names).find_each do |cp|
			cp.users.where(user_filter).find_each do |u|
				users << u
			end
		end

		users.uniq{|u| u[:id]}
	end

end
