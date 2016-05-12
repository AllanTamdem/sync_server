class LabgencyController < ApplicationController

	before_action :authenticate_user!
	before_action do
		unless current_user.try(:admin?)
		  redirect_to root_path
		end
	end

	include ActionView::Helpers::DateHelper

	def index

		@logs = get_logs

	end

	def logs

		@logs = get_logs

		render layout: false
	end

	def catalog

		exec_async {

			url = Rails.configuration.labgency_api

			resp = Net::HTTP.get_response(URI.parse(url))
			labgency_catalog = resp.body
			
			data = JSON.parse(labgency_catalog)

			render :json => {data: data}

		}
	end

	def run_batch

		exec_async {

			result = LabgencyApplyCidWorker.new.perform

			render :json => {result: result}

		}
	end

	private
		def get_logs
			Log.where(action_type: 'BATCH_LABGENCY_SET_CID').last(20).reverse.map{|log|
				{
					created_at: log[:created_at],
					created_at_ago: time_ago_in_words(log[:created_at]) + ' ago',
					content: log[:content]
				}
			}
		end

end