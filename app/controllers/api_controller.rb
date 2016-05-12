class ApiController < ApplicationController
  protect_from_forgery with: :null_session


	include PathHelper
	include S3Helper
	include UsersHelper

  #authenticate the user with api-key either as a url parameter or in the header
  before_action do
  	api_key = params['api-key']

  	if api_key.blank?
  		api_key = request.headers['api-key']
  	end

  	if api_key.blank?
  		headers["WWW-Authenticate"] = "No valid api-key provided"
		render json: {error: "Unauthorized"}, status: :unauthorized
  	else
	  	unless api_key.blank?
	  		@user = User.find_by api_key: api_key
	  	end

	  	if @user.nil?
	  		headers["WWW-Authenticate"] = "No valid api-key provided"
			render json: {error: "Unauthorized"}, status: :unauthorized
	  	end
	end	

  end


  #get the list of files in s3
  def files

	repository_folder = user_get_repository_folder(@user)

	if repository_folder == nil
		render :json => { error: 'you need to belong to a content provider with a "repository folder" setup'}
	else
	  	files = s3_get_files(repository_folder)

	  	files = files.map{ |f|
	  		{
	  			key: f[:key],
	  			meta: f[:head][:meta],
	  			content_type: f[:head][:content_type],
	  			content_length: f[:head][:content_length]
	  		}
	  	}

		create_log('LIST_REPOSITORY_FILES', files)

	  	render json: files
	end
  end


  #delete a file from s3
  def delete

  	key = params[:key]

  	if key.blank?
		render json: {error: "missing 'key' parameter"}, status: :bad_request
		return
  	end

  	if !user_has_access?(@user, key)
		render json: {error: "forbidden"}, status: :forbidden
		return
	end


  	if !s3_exists?(key)
		render json: {error: "file doesn't exist"}, status: :not_found
		return
	end

	s3_delete_file(key)

	response = {status: 'done'}

	create_log('DELETE_FILE', response)

  	render json: response

  end


  def presigned_post

	repository_folder = user_get_repository_folder(@user)

	if repository_folder == nil
		render :json => { error: 'you need to belong to a content provider with a "repository folder" setup'}
	else

		path = path_concat(repository_folder, params[:path])

		meta_keys = params[:meta_keys] or []

		if meta_keys.nil?
			meta_keys = []
		end

		form = s3_get_form(path, meta_keys)

		output = { url: form[:url],
			fields: {
				AWSAccessKeyId: form[:fields]['AWSAccessKeyId'],
				key: form[:fields]['key'],
				policy: form[:fields]['policy'],
				signature: form[:fields]['signature'],
				Secure: form[:fields]['Secure'],
				file: nil
			}
		}

		#adding the meta keys
		meta_keys.each{ |m|
			output[:fields]['x-amz-meta-' + m] = nil
		}	

		create_log('GET_PRESIGNED_POST', output)

		render :json => output
	end

  end


  private

  def create_log  action_type, response

  	content = {
			url: request.url,
			method: request.method,
			header_api_key: request.headers['api-key'],
			response: response
		}

	Log.create!(
		interface: 'API',
		user_ip: request.remote_ip,
		user: ActiveSupport::JSON.encode(@user).to_s,
		action_type: action_type,
		content: ActiveSupport::JSON.encode(content).to_s)
  end

end
