class S3Controller < ApplicationController
	
	before_action :authenticate_user!

	include PathHelper
	include S3Helper
	include UsersHelper
	include SiteSettingsHelper
	include MetadataHelper
	include ContentProvidersHelper
		
	def get_files

		exec_async {

				filter = params[:filter]
				detailed = params[:detailed] == 'true'

				if user_has_access?(current_user, filter) then

					s3_info = get_content_provider_s3_info(filter)

					if detailed
						files_result = s3_get_files_detailed(s3_info, filter)
					else
						files_result = s3_get_files(s3_info, filter)
					end

					if files_result[:error] != nil
						render :json => {err: files_result[:error], data: [], detailed: detailed}
					else

						files_all = files_result[:files]

						files_json = files_all.select { |f| f[:key].end_with?('.json') }
						files = files_all.select { |f| !(f[:key].end_with?('.json')) }

						files_json_extra = []

						files_json.each { |fj|
							file = files.find{ |f|
								f[:key] + '.json' == fj[:key]
							}
							if file
								file[:metadata_file] = fj
							else
								files_json_extra << fj
							end
						}

						render :json => {err: nil, data: files + files_json_extra, detailed: detailed}
					end
				else
					render json: {error: "Unauthorized"}, status: :unauthorized
				end
			}
	end


	def get_file_size
		exec_async {

				key = params[:key]
				content_provider = params[:cp]

				if user_has_access?(current_user, key) then

					s3_info = get_content_provider_s3_info(content_provider)

					size = s3_get_file_size(s3_info, key)

					render :json => {key: key, size: size}
				else
					render json: {error: "Unauthorized"}, status: :unauthorized
				end
		}
	end


	def get_files_with_last_modified_date

  	exec_async {

			client = params[:client] || ''

			repository_folders = user_get_repository_folders(current_user)

			if user_can_see_client?(current_user, client)				

				s3_info = get_content_provider_s3_info(client)

				files = s3_get_files_with_last_modified_date(s3_info, client)

				render :json => {data: files}
			else
				render :json => {error: "you don't have access to the client '#{client}'"}
			end

		}
		
	end

	def validate_metadata
		metadata = params[:metadata]

		errors = metadata_validate metadata

		if errors.count > 0
			render :json => {errors: errors}
			return
		end

		# schema = sites_settings_metadata_validation_schema
		# errors = JSON::Validator.fully_validate(schema, metadata)		

		# if errors.count > 0
		# 	render :json => {errors: errors, schema: schema}
		# 	return
		# end

		render :json => {errors: []}
	end


	def set_metadata

		key = params[:key]
		metadata = params[:metadata]
		content_provider = params[:cp]

		if !user_has_access?(current_user, key)
			render :json => {error: 'Unauthorized'}
		else

			errors = metadata_validate metadata

			if errors.count > 0
				render :json => {errors: errors}
				return
			end

			if errors.count == 0

				s3_info = get_content_provider_s3_info(content_provider)

				type = JSON.parse(metadata)['type']

				s3_create_file(s3_info, key, metadata)
				SaveFileTypeForAnalyticsWorker.perform_async(s3_info, key[0..-6], nil, type)
				create_log('SET_FILE_METADATA', {key: key, metadata: metadata.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})})
				render :json => {errors: []}
			end
		end
	end


	def delete
		if request.delete? && !params[:key].blank?

			key = params[:key]
			content_provider = params[:cp]

			if !user_has_access?(current_user, key)
  			render :json => {status: 'unauthorized'}
			else

				s3_info = get_content_provider_s3_info(content_provider)

				response = {}
				response[:key] = key

		  	if s3_exists?(s3_info, key)

					s3_delete_file(s3_info, key)

			  	if s3_exists?(s3_info, key)
						response[:error] = "The file '#{key}' couldn't be deleted"
					end

					create_log('DELETE_FILE', response)
				else
					response[:error] = "The file '#{key}' doesn't exist"
				end

    			render json: response
	    	end
		end
	end


	def get_form

		param_path = params[:path]
				content_provider = params[:cp]

		if param_path.end_with?('/') == false
			param_path += '/'
		end

		if !user_has_access?(current_user, param_path)
			render :json => {error: 'You are not autorized to upload files to this folder'}			
		else
			if !(/^([a-zA-Z\.0-9\-_ ]*\/)+$/ =~ param_path)
				render :json => { error: "Folders can't contains any characters other than letters, numbers and the characters _, - and /"}
			else

				s3_info = get_content_provider_s3_info(content_provider)

				path = path_prettify(param_path)

				form = s3_get_form(s3_info, path, JSON.parse(params[:metaFields] || '[]'))

				render :json => { form: form }
			end
		end
	end


	def modify_file

		param = JSON.parse(params[:param])
		content_provider = params[:cp]

		old_key = param['old_key']
		new_path_with_key = param['new_path_with_key']
		metadata = param['metadata']


		if !user_has_access?(current_user, old_key)
			render :json => {status: 'unauthorized'}
		elsif  !user_has_access?(current_user, new_path_with_key)
			render :json => {error: 'You are not autorized to put files in this folder'}
		else
			all_jobs = get_all_jobs

			if all_jobs.any?{|job| job[:key] == old_key}

				render :json => { job_id: nil, error: "There's already an operation on the file '#{old_key}'.", params: nil }

			else

				custom_param = {
					owner_email: current_user.email,
					owner_id: current_user.id,
					description: "Modifying '#{old_key}' to '#{new_path_with_key}'.",
					key: old_key
				}


				while new_path_with_key.include? "//"
					new_path_with_key.gsub!("//", "/")
				end

				s3_info = get_content_provider_s3_info(content_provider)
				
	    	job_id = S3ModifyFileWorker.perform_async(custom_param, s3_info, old_key, new_path_with_key, metadata)

				create_log('MODIFY_FILE', param)

				render :json => { job_id: job_id, error: nil, params: custom_param }

			end
		end
	end


	def get_jobs

		all_jobs = get_all_jobs

		owned_jobs = []

		all_jobs.each do |job|
			if job[:owner_id] == current_user.id
				owned_jobs << job
			end
		end

		render :json => { jobs: owned_jobs}

	end



	def sign_auth

    hmac = HMAC::SHA1.new('nppiEYDYBmpw/YGkEqSoxO8ri51DKDEG/wjI7eaY')
    hmac.update(params["to_sign"])

    encoded = Base64.encode64("#{hmac.digest}").gsub("\n",'')

    render :text => encoded, :status => 200 and return

	end



	private


	# Get all the jobs from Sidekiq
	# get the running jobs and the jobs in the queue
	def get_all_jobs
		jobs = []

		workers = Sidekiq::Workers.new
		workers.each do |process_id, thread_id, work|
			# process_id is a unique identifier per Sidekiq process
			# thread_id is a unique identifier per thread
			# work is a Hash which looks like:
			# { 'queue' => name, 'run_at' => timestamp, 'payload' => msg }
			# run_at is an epoch Integer.

			args = work['payload']['args']

			jobs << {type: 'running', job_id: work['payload']['jid'], description: args[0]['description'], owner_id: args[0]['owner_id'], key: args[0]['key'] }
		end

		queue = Sidekiq::Queue.new
		queue.each do |job|
			# job.klass # => 'MyWorker'
			# job.args # => [1, 2, 3]
			# job.delete if job.jid == 'abcdef1234567890'			

			args = job.args
			jobs << {type: 'queued', job_id: job.jid, description: args[0]['description'], owner_id: args[0]['owner_id'], key: args[0]['key']}
		end

		jobs
	end	


	def create_log  action_type, response

		content = {
			url: request.url,
			method: request.method,
			response: response
		}

		Log.create!(
			interface: 'WEB_UI',
			user_ip: request.remote_ip,
			user: ActiveSupport::JSON.encode(current_user).to_s,
			action_type: action_type,
			content: ActiveSupport::JSON.encode(content).to_s)
	end

end