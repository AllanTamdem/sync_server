module CacheHelper

	include MediaspotHelper
  include FetchAnalyticsHelper

	def cache_fetch cache_key

		data = $redis.get(cache_key)

		if data == nil

			data = yield

			# for analytics, the cache should not be empty
			# it should be set by the batch every hour
			Rails.logger.info("CacheHelper. setting #{cache_key}")

			$redis.set(cache_key, data)

		end

		data

	end
	

	def cache_write cache_key

		data = yield

		$redis.set(cache_key, data)

	end	



	def cache_read cache_key

		$redis.get(cache_key)

	end	


	def cache_populate_analytics mediaspots

		clients_names = []

		mediaspots.each{ |mediaspot|

			mediaspot_id = mediaspot['_id']

			mediaspot_get_clients(mediaspot).each{ |client|  				

				client_name = client['ClientName']['_value']

				if clients_names.include?(client_name) == false
					clients_names << client_name
				end

				# caching data specific to a client and a mediaspot
				pvt_populate_analytics(client_name, mediaspot_id)

			}

		}

		# caching data specific to only a client
		clients_names.each{ |client_name|
			pvt_populate_analytics(client_name, nil)
		}

		nil

	end

	private

		def pvt_populate_analytics client_name, mediaspot_id

			time_periods = ['hour', 'day', 'month']

  		if mediaspot_id.nil?
				# DOWNLOADS PER MEDIASPOT
				time_periods.each{ |time_period|
					cache_write("get_unique_mediaspots-#{client_name}-#{time_period}") {
						get_unique_mediaspots(client_name, time_period).to_json
					}

					cache_write("get_downloads_per_mediaspot-#{client_name}-#{time_period}") {
						get_downloads_per_mediaspot(client_name, time_period).to_json
					}
				}
  		end

			# DOWNLOADS PER FILE
			time_periods.each{ |time_period|
				cache_write("get_unique_files-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_unique_files(client_name, mediaspot_id, time_period).to_json
				}
				cache_write("get_downloads_per_file-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_downloads_per_file(client_name, mediaspot_id, time_period).to_json
				}
			}

			# DOWNLOADS PER CONTENT TYPE
			time_periods.each{ |time_period|
				cache_write("get_unique_file_types-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_unique_file_types(client_name, mediaspot_id, time_period).to_json
				}
				cache_write("get_downloads_per_content_type-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_downloads_per_content_type(client_name, mediaspot_id, time_period).to_json
				}
			}

			# DOWNLOADS PER CONTENT TYPE
			time_periods.each{ |time_period|
				cache_write("get_unique_file_types-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_unique_file_types(client_name, mediaspot_id, time_period).to_json
				}
				cache_write("get_downloads_per_content_type-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_downloads_per_content_type(client_name, mediaspot_id, time_period).to_json
				}
				cache_write("get_unique_device_types-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_unique_device_types(client_name, mediaspot_id, time_period).to_json
				}
				cache_write("get_downloads_per_device_type-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_downloads_per_device_type(client_name, mediaspot_id, time_period).to_json
				}
			}

			# FAILED DOWNLOADS
			time_periods.each{ |time_period|
				cache_write("get_unique_mediaspots-#{client_name}-#{time_period}") {
					get_unique_mediaspots(client_name, time_period).to_json
				}
				cache_write("get_failed-downloads-#{mediaspot_id}-#{client_name}-#{time_period}") {
					get_failed_downloads(client_name, mediaspot_id, time_period).to_json
				}
			}

			# TOP FILES
			cache_write("get_file_distribution_from_time-#{client_name}-#{mediaspot_id}-") {
				get_file_distribution_from_time(client_name, mediaspot_id, nil).to_json
			}

		end

end