class S3v2Controller < ApplicationController
	

	include ActionView::Helpers::NumberHelper

	include MetadataHelper
	include ContentProvidersHelper
	include S3v2Helper
	include UsersHelper


	def get_files_as_tree

		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], [params[:path]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				response = s3_get_tree(s3_info, params[:path] || '')

				render json: response

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}

	end	

	def get_files_with_last_modified_date

		exec_async {

			if params[:client].blank? == false

				render :json => get_files_with_last_modified_date__one(params[:client] || '')

			else

				result = {}

				if params[:clients] != nil && params[:clients].kind_of?(Array)

					params[:clients].each{|client|
						result[client] = get_files_with_last_modified_date__one(client || '')
					}

				end

				render :json => result

			end

		}
		
	end



	def get_file_size
		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], [params[:key]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				size = s3_get_file_size(s3_info, params[:key])

				render :json => {key: params[:key], size: size}
			else
				render json: {error: "Unauthorized"}, status: :unauthorized
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

		render :json => {errors: []}
	end


	def set_metadata

		if user_has_s3_access?(current_user, params[:bucket], [params[:key]])

			key = params[:key]
			metadata = params[:metadata]

			errors = metadata_validate metadata

			if errors.count > 0
				render :json => {errors: errors}
				return
			end

			if errors.count == 0

				type = JSON.parse(metadata)['type']

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				s3_put_file(s3_info, key, metadata)

				SaveFileTypeForAnalyticsWorker.perform_async(s3_info, key[0..-6], nil, type)
				# create_log('SET_FILE_METADATA', {key: key, metadata: metadata.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})})

				save_file_repo_log(current_user.email, 'set_metadata', {
					bucket: params[:bucket],
					file: params[:key],
					metadata: params[:metadata].encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
				}.to_json)

				render :json => {errors: []}
				return
			end

		else
			render json: {error: "Unauthorized"}, status: :unauthorized
		end

	end


	def fetch_metadata

		exec_async {
			
			if user_has_s3_access?(current_user, params[:bucket], [params[:key]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				response = s3_read_object(s3_info, params[:key])

				render json: response

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}

	end


	def create_folder

		exec_async {
			
			if user_has_s3_access?(current_user, params[:bucket], [params[:folder_path]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				result = s3_create_folder(s3_info, params[:folder_path])

				save_file_repo_log(current_user.email, 'create_folder', {
					bucket: params[:bucket],
					folder_path: params[:folder_path]
				}.to_json)

				render json: result

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}

	end



	def delete_files

		exec_async {
			
			if user_has_s3_access?(current_user, params[:bucket], (params[:files]||[]) + (params[:folders]||[]))

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				deleted_files = s3_delete_files(s3_info, params[:files], params[:folders])

				save_file_repo_log(current_user.email, 'delete_files',
				{
					bucket: params[:bucket],
					deleted_files: deleted_files
				}.to_json)

				render json: nil

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}

	end



	def cut_paste_files

		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], (params[:files]||[]) + (params[:folders]||[]) + [params[:destination]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				result = s3_copy_files(s3_info,  params[:files], params[:folders], params[:destination], true)

				save_file_repo_log(current_user.email, 'cut_paste_files', {
					bucket: params[:bucket],
					files: params[:files],
					folders: params[:folders],
					destination: params[:destination],
				}.to_json)

				render json: result

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}
	end


	def copy_paste_files
		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], (params[:files]||[]) + (params[:folders]||[]) + [params[:destination]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				result = s3_copy_files(s3_info,  params[:files], params[:folders], params[:destination], false)

				save_file_repo_log(current_user.email, 'copy_paste_files', {
					bucket: params[:bucket],
					files: params[:files],
					folders: params[:folders],
					destination: params[:destination],
				}.to_json)

				render json: result

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}
	end


	def rename_file
		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], [params[:old_key], params[:new_key]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				result = s3_rename_file(s3_info, params[:old_key], params[:new_key])

				save_file_repo_log(current_user.email, 'rename_file', {
					bucket: params[:bucket],
					old_key: params[:old_key],
					new_key: params[:new_key]
				}.to_json)

				render json: result

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}
	end



	def sign_auth_upload

		bucket_and_key = params[:to_sign].split("\n")[5]

		key = bucket_and_key[params[:bucket].size+2..-1]
		
		if user_has_s3_access?(current_user, params[:bucket], [key])

			s3_info = find_s3_info_by_bucket_name(params[:bucket])

	    encoded = s3_get_signed_upload(s3_info, params[:to_sign])

	    render :text => encoded, :status => 200

		else
			render json: {error: "Unauthorized"}, status: :unauthorized
		end

	end
	

	def file_download_url

		exec_async {

			if user_has_s3_access?(current_user, params[:bucket], [params[:key]])

				s3_info = find_s3_info_by_bucket_name(params[:bucket])

				url = s3_file_download_url(s3_info, params[:key])

				render :text => url, :status => 200

			else
				render json: {error: "Unauthorized"}, status: :unauthorized
			end
		}

	end
	

	def upload_complete

		save_file_repo_log(current_user.email, 'upload_complete', params[:details].to_json)

		render json: nil

	end

	private



		def get_files_with_last_modified_date__one client

				repository_folders = user_get_repository_folders(current_user)

				result = nil

				if user_can_see_client?(current_user, client)				

					s3_info = get_content_provider_s3_info(client)

					cp = get_content_provider_by_technical_name(client)

					path = nil

					if cp == nil
						path = client
					else
						path = cp[:path_in_bucket]

						if path.blank?
							path = cp[:technical_name]
						end
					end

					files = s3_get_files_with_last_modified_date(s3_info, path)

					result = {data: files}
				else
					result = {error: "you don't have access to the client '#{client}'"}
				end

				return result
			
		end



end
