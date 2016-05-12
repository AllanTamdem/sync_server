class AnalyticsController < ApplicationController

	before_action :authenticate_user!

	include FetchAnalyticsHelper
	include CacheHelper


	def downloads

		args = params.permit(:client, :mediaspot_id, :period, :type)
		result = '{}'

		if args[:type] == 'mediaspot'

			result = pvt_downloads_per_mediaspot(args[:client], args[:period])

		elsif args[:type] == 'file'

			result = pvt_downloads_per_file(args[:mediaspot_id], args[:client], args[:period])

		elsif args[:type] == 'content-type'

			result = pvt_downloads_per_content_type(args[:mediaspot_id], args[:client], args[:period])

		elsif args[:type] == 'device-type'

			result = pvt_downloads_per_device_type(args[:mediaspot_id], args[:client], args[:period])

		elsif args[:type] == 'failed-downloads'

			result = pvt_failed_downloads(args[:mediaspot_id], args[:client], args[:period])

		end
				

		render :json => "{
			\"result\": #{result}, 
			\"args\": #{args.to_json}
		}"

	end


	def files_distribution

		client = params['client']
		mediaspot_id = params['mediaspot_id']
		days = params['days']

		time = nil
		if days.blank?
			days = nil
		else
			time = DateTime.now - (days.to_i)
		end

		if mediaspot_id.blank?
			mediaspot_id = nil
		end

		data = nil
		if time == nil
			data = cache_fetch("get_file_distribution_from_time-#{client}-#{mediaspot_id}-") {
				get_file_distribution_from_time(client, mediaspot_id, time).to_json
			}
		else
			data = get_file_distribution_from_time(client, mediaspot_id, time).to_json
		end



		render :json => "{
			\"data\": #{data}
		}"

	end

	private 

		def pvt_downloads_per_mediaspot client, period		

				mediaspots = cache_fetch("get_unique_mediaspots-#{client}-#{period}") {
					get_unique_mediaspots(client, period).to_json
				}

				data = cache_fetch("get_downloads_per_mediaspot-#{client}-#{period}") {
					get_downloads_per_mediaspot(client, period).to_json
				}

				return "{
					\"titles\": #{mediaspots}, 
					\"data\": #{data}
				}"

		end


		def pvt_downloads_per_file mediaspot_id, client, period

			files = cache_fetch("get_unique_files-#{mediaspot_id}-#{client}-#{period}") {
				get_unique_files(client, mediaspot_id, period).to_json
			}
			data = cache_fetch("get_downloads_per_file-#{mediaspot_id}-#{client}-#{period}") {
				get_downloads_per_file(client, mediaspot_id, period).to_json
			}

			return "{
				\"titles\": #{files}, 
				\"data\": #{data}
			}"			

		end

		def pvt_downloads_per_content_type mediaspot_id, client, period

			file_types = cache_fetch("get_unique_file_types-#{mediaspot_id}-#{client}-#{period}") {
				get_unique_file_types(client, mediaspot_id, period).to_json
			}

			data = cache_fetch("get_downloads_per_content_type-#{mediaspot_id}-#{client}-#{period}") {
				get_downloads_per_content_type(client, mediaspot_id, period).to_json
			}

			return "{
				\"titles\": #{file_types}, 
				\"data\": #{data}
			}"
		end


		def pvt_downloads_per_device_type mediaspot_id, client, period

			device_types = cache_fetch("get_unique_device_types-#{mediaspot_id}-#{client}-#{period}") {
				get_unique_device_types(client, mediaspot_id, period).to_json
			}

			data = cache_fetch("get_downloads_per_device_type-#{mediaspot_id}-#{client}-#{period}") {
				get_downloads_per_device_type(client, mediaspot_id, period).to_json
			}

			return "{
				\"titles\": #{device_types}, 
				\"data\": #{data}
			}"
		end


		def pvt_failed_downloads mediaspot_id, client, period

			mediaspots = [];

			if mediaspot_id.blank?			
				mediaspots = cache_fetch("get_unique_mediaspots-#{client}-#{period}") {
					get_unique_mediaspots(client, period).to_json
				}
			else
				mediaspots = [mediaspot_id]
			end

			data = cache_fetch("get_failed-downloads-#{mediaspot_id}-#{client}-#{period}") {
				get_failed_downloads(client, mediaspot_id, period).to_json
			}

			return "{
				\"titles\": #{mediaspots}, 
				\"data\": #{data}
			}"
		end
	
end