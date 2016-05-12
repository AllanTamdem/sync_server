class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception



	def save_tr069_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_tr069, action, details) 
	end

	def save_file_repo_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_repo, action, details) 
	end

	def save_profile_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_profile, action, details) 
	end

	def save_users_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_users, action, details) 
	end

	def save_content_providers_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_content_providers, action, details) 
	end

	def save_site_settings_log(user, action, details)
		SaveApplicationLogWorker.perform_async(user, ApplicationLog::Action_type_content_providers, action, details) 
	end



	def exec_async

		EM.defer do

    	begin
    					
				yield

			rescue => e

				Rails.logger.fatal(e.message + ' ' + (e.backtrace|| []).join(''))

				render json: {error: "An error occured"}, status: 500
			end

			request.env['async.callback'].call(response)
		end

		throw :async

	end


end
