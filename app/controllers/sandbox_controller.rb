class SandboxController < ApplicationController	


	include WorkersHelper

	before_action :authenticate_user!
	before_action do
		unless current_user.try(:admin?)
		  redirect_to root_path
		end
	end

	@@base_url = Rails.configuration.node_ws_api


	def index

		resp = Net::HTTP.get_response(URI.parse(@@base_url + '/mediaspots'))

		@lookup = resp.body
		
	end


	def test

		id = params['id']

		query = "?message=INFORMREQUEST&mediaspot_id=#{id}"

		resp = Net::HTTP.get_response(URI.parse(@@base_url + query))

		render :text => resp.body
	end

	def test2
		render json: AnalyticsDownloadsPerHour.count
	end

	def sidekiq_jobs

		exec_async {
			render json: workers_get_all_raw
		}
	end


end