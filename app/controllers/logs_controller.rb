class LogsController < ApplicationController

	before_action :authenticate_user!
	before_action :only_admin, except: [:create]

	def index
		lines = params[:lines] || 100
		if Rails.env == "production" or Rails.env == "staging"
		  # @logs = `tail -n #{lines} ../../shared/log/unicorn.stdout.log`
		  # @logs2 = `tail -n #{lines} ../../shared/log/unicorn.stderr.log`


		  
		  if Rails.env == "staging"
		  	@logs = `tail -n #{lines} ../../shared/log/staging.log`
		  else
		  	@logs = `tail -n #{lines} ../../shared/log/production.log`
		  end

		  @logs2 = `tail -n #{lines} ../../shared/log/thin.0.log`
		  @logs3 = `tail -n #{lines} ../../shared/log/thin.1.log`
		  @logs4 = `tail -n #{lines} ../../shared/log/thin.2.log`
		else
		  @logs = `tail -n #{lines} log/development.log`
		end
	end

	def sidekiq
		lines = params[:lines] || 100
		if Rails.env == "production" or Rails.env == "staging"
		  @logs = `tail -n #{lines} ../../shared/log/sidekiq.log`
		else
		  @logs = ""
		end
		render "index"
	end

	def cron
		lines = params[:lines] || 100
		if Rails.env == "production" or Rails.env == "staging"
		  @logs = `tail -n #{lines} ../../shared/log/cron_log.log`
		else
		  @logs = `tail -n #{lines} log/cron_log.log`
		end
		render "index"
	end

	def node_ws
		lines = params[:lines] || 100
		if Rails.env == "production" or Rails.env == "staging"
		  @logs = `tail -n #{lines} ../../shared/log/node_ws_log.log`
		else
		  @logs = ''
		end
		render "index"
	end
	

	def create_rails_log

		content = {
			url: params[:url],
			content: params[:content]
		}

		error = {
			interface: 'WEB_UI',
			action_type: params[:action_type],
			user_ip: request.remote_ip,
			user: current_user.email,
			content: ActiveSupport::JSON.encode(content).to_s
		}

		Rails.logger.error(ActiveSupport::JSON.encode(error).to_s)

		render :json => params[:content]
	end
	

	def only_admin

		unless current_user.try(:admin?)
		  redirect_to root_path
		end

	end

end