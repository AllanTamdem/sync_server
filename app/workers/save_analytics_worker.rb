class SaveAnalyticsWorker
  include Sidekiq::Worker

  sidekiq_options retry: false
  
  require 'date'

  include Tr069Helper
  include MediaspotHelper
  include FetchAnalyticsHelper
  include CacheHelper


	Extensions_to_exclude = ['.json', '.png', '.jpg']


  def perform_all
  	
		cron_log "----STARTING SaveAnalyticsWorker"

  	if Rails.env.production? or Rails.env.test?
  		start(nil, nil)
  	else
  		#if not production, we wait 5mn and update the cache
  		#because the analytics are store on an other server but the cache is local
  		sleep(5.minutes)
			log "populating cache"
  		cache_populate_analytics(tr069_get_devices())
  	end

		cron_log "----ENDING SaveAnalyticsWorker"
  end

  def perform mediaspot_id, client_number
  	start(mediaspot_id, client_number)
  end

  

  def start mediaspot_id, client_number

		reports = []

		mediaspots = []

		if mediaspot_id == nil
			mediaspots = tr069_get_devices()
		else
			mediaspots << tr069_get_device(mediaspot_id)
		end

		mediaspots.each{ |mediaspot|

			reports << process_mediaspot(mediaspot, client_number)

		}

		log "populating cache"
  	cache_populate_analytics mediaspots
  	
  	if mediaspot_id != nil and client_number != nil
  		tr069_refresh_client_on_device_if_not_in_queue(mediaspot_id, client_number)
  	end

		cron_log reports.inspect  	

		nil
  end
  
  def process_mediaspot mediaspot, p_client_number

  	mediaspot_id = mediaspot['_id']
  	mediaspot_name = mediaspot['mediaspotName']

  	report = {
  		mediaspot_id: mediaspot_id,
  		mediaspot_name: mediaspot_name,
  		clients: []
  	}

		if mediaspot.key?('InternetGatewayDevice') and
			mediaspot['InternetGatewayDevice'].key?('X_orange_tapngo') and
			mediaspot['InternetGatewayDevice']['X_orange_tapngo'].key?('Clients')

			mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'].keys.each do |client_number|

				if ["_object", "_writable", "_timestamp"].include?(client_number) == false and
					(p_client_number == nil or p_client_number.to_s == client_number.to_s)

					client = mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number]
					client_name = client['ClientName']['_value']					

					client_report = {
						client_name: client_name,
						errors: []
					}

					if client.key?('DownloadAnalytics') and
						client['DownloadAnalytics'].key?('_value') and
						client['DownloadAnalytics']['_value'] != ''

						analytics = nil

						begin

							serialized_analytics = ActiveSupport::Gzip.decompress(Base64.decode64(client['DownloadAnalytics']['_value']))

							if serialized_analytics.blank? == false
								analytics = JSON.parse(serialized_analytics)
							end

						rescue  Zlib::GzipFile::Error => gzip_error

							error =  "Zlib::GzipFile::Error " + gzip_error.message + ' ' + (gzip_error.backtrace|| []).join('')
							client_report[:errors] << error

							log_error "error on mediaspot_id #{mediaspot_id}, client_name #{client_name} : " + error

						rescue  JSON::ParserError => json_error

							error = "JSON::ParserError " + json_error.message + ' ' + (json_error.backtrace|| []).join('')							
							client_report[:errors] << error

							log_error "error on mediaspot_id #{mediaspot_id}, client_name #{client_name} : " + error

						end

						if analytics != nil

					  	result_files_downloads = save_client_files(mediaspot_id, mediaspot_name, client_name, analytics['files'])

					  	client_report[:downloads_per_hour] = result_files_downloads[:report]

					  	client_report[:device_types] = save_client_device_types(mediaspot_id, mediaspot_name, client_name, analytics['devicetypes'])

					  	client_report[:download_speeds] = save_client_download_speeds(mediaspot_id, mediaspot_name, client_name, analytics['downloadspeeds'])

					  	client_report[:failed_downloads] = save_client_failed_downloads(mediaspot_id, mediaspot_name, client_name, analytics['faileddownloads'])

					  	if result_files_downloads[:max_hour] != nil
					  		# we go back one hour
					  		max_hour_epoch = (result_files_downloads[:max_hour] - 1) * 3600

					  		# we set the new AnalyticsStartTime if it's a different one
					  		if client.key?('AnalyticsStartTime') == false or
					  			client['AnalyticsStartTime'].key?('_value') == false or
					  			client['AnalyticsStartTime']['_value'].to_s != max_hour_epoch.to_s

						  		param_analytics_start_time = "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}.AnalyticsStartTime"

						  		if Rails.env.production?
										log "set AnalyticsStartTime to #{max_hour_epoch} on #{mediaspot_id}.#{client_number}"
						  			tr069_set_parameter_if_not_in_queue(mediaspot_id, param_analytics_start_time, max_hour_epoch)
						  			tr069_refresh_client_on_device_if_not_in_queue(mediaspot_id, client_number)
						  		end

					  		end
					  	end

						end

					else

						client_report[:errors] << 'No analytics'

					end

					report[:clients] << client_report

				end

			end

		end

  	report

  end

  private

  	def get_file_type file

  		if @file_types == nil
  			@file_types = AnalyticsFileType.all.to_a
  		end

  		entry = @file_types.find{|e|
  			e['file'] == file
  		}

  		if entry != nil
  			return entry['type']
  		end

  		nil
  	end


	  # 
	  # 
	  # 
	  # 
	  # 
  	def aapopulate_cache_all mediaspots

  		clients_names = []

  		mediaspots.each{ |mediaspot|

  			mediaspot_id = mediaspot['_id']

  			mediaspot_get_clients(mediaspot).each{ |client|  				

  				client_name = client['ClientName']['_value']

  				if clients_names.include?(client_name) == false
  					clients_names << client_name
  				end

  				# caching data specific to a client and a mediaspot
  				aapopulate_cache(client_name, mediaspot_id)

  			}

  		}

			# caching data specific to only a client
  		clients_names.each{ |client_name|
				aapopulate_cache(client_name, nil)
  		}

  	end

  	def aapopulate_cache client_name, mediaspot_id  		

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

	  # 
	  # 
	  # 
	  # 
	  # 
	  def save_client_files mediaspot_id, mediaspot_name, client_name, files

	  	report = {
	  		creates: 0,
	  		updates: 0
	  	}

	  	max_hour = nil

	  	files.sort { |x,y| x['filename'] <=> y['filename'] }.each { |file|

	  		if Extensions_to_exclude.any?{|extension| file['filename'].end_with?(extension) }
	  			next
	  		end

	  		size = file['size'].to_i

	  		sorted_files = file['downloadedbytes'].sort { |x,y| x['hour'].to_i <=> y['hour'].to_i }

	  		file_max_hour = sorted_files.last['hour'].to_i

  			if max_hour == nil or file_max_hour > max_hour
  				max_hour = file_max_hour
  			end

	  		sorted_files.each { |entry|

	  			time = Time.at(entry['hour'].to_i * 3600).to_datetime
	  			bytes = entry['bytes'].to_i

	  			existing_entry = AnalyticsDownloadsPerHour.where(
	  				mediaspot_id: mediaspot_id,
	  				mediaspot_name: mediaspot_name,
	  				client_name: client_name,
	  				file: file['filename'],
	  				size: size,
	  				time: time,
	  			).first

	  			if existing_entry == nil

	  				file_type = get_file_type(client_name + file['filename'])

	  				created = AnalyticsDownloadsPerHour.create!(
		  				mediaspot_id: mediaspot_id,
		  				mediaspot_name: mediaspot_name,
		  				client_name: client_name,
		  				file: file['filename'],
		  				size: size,
		  				time: time,
		  				file_type: file_type,
		  				bytes: bytes
						)						

						report[:creates] = report[:creates] + 1

						log "created: #{created.inspect}"

	  			elsif existing_entry[:bytes] != bytes

	  				existing_entry.update_attributes(
		  				bytes: bytes
						)

						report[:updates] = report[:updates] + 1

						log "updated: #{existing_entry.inspect}"

	  			end

	  		}

	  	}

	  	{report: report, max_hour: max_hour}
	  end

	  # 
	  # 
	  # 
	  # 
	  # 
	  def save_client_device_types mediaspot_id, mediaspot_name, client_name, device_types

	  	report = {
	  		creates: 0,
	  		updates: 0
	  	}

	  	if device_types.is_a?(Array)

	  		device_types.sort { |x,y| x['devicetype'] <=> y['devicetype'] }.each { |device_type|

	  			device_type['accesses'].sort { |x,y| x['hour'].to_i <=> y['hour'].to_i }.each{ |access|

	  				time = Time.at(access['hour'].to_i * 3600).to_datetime
	  				accesses = access['numaccesses'].to_i

		  			existing_entry = AnalyticsDeviceTypesPerHour.where(
		  				mediaspot_id: mediaspot_id,
		  				mediaspot_name: mediaspot_name,
		  				client_name: client_name,
		  				device_type: device_type['devicetype'],
		  				time: time,
		  			).first

		  			if existing_entry == nil

		  				created = AnalyticsDeviceTypesPerHour.create!(
			  				mediaspot_id: mediaspot_id,
			  				mediaspot_name: mediaspot_name,
			  				client_name: client_name,
			  				device_type: device_type['devicetype'],
			  				time: time,
			  				accesses: accesses
							)						

							report[:creates] = report[:creates] + 1

							log "created: #{created.inspect}"

		  			elsif existing_entry[:accesses] != accesses

		  				existing_entry.update_attributes(
			  				accesses: accesses
							)

							report[:updates] = report[:updates] + 1

							log "updated: #{existing_entry.inspect}"

		  			end

	  			}
	  		}

	  	end

	  	report	  	

	  end

	  # 
	  # 
	  # 
	  # 
	  # 
	  def save_client_download_speeds mediaspot_id, mediaspot_name, client_name, download_speeds

	  	report = {
	  		creates: 0,
	  		updates: 0
	  	}

			existing_entry = AnalyticsDownloadSpeeds.where(
				mediaspot_id: mediaspot_id,
				client_name: client_name
			).first

			if existing_entry == nil

				created = AnalyticsDownloadSpeeds.create!(
					mediaspot_id: mediaspot_id,
					client_name: client_name,
					download_speeds: download_speeds
				)

				report[:creates] = report[:creates] + 1

				log "created: #{created.inspect}"

			elsif existing_entry[:download_speeds] != download_speeds

				existing_entry.update_attributes(
					download_speeds: download_speeds
				)

				report[:updates] = report[:updates] + 1

				log "updated: #{existing_entry.inspect}"

			end

			report

	  end

	  # 
	  # 
	  # 
	  # 
	  # 
	  def save_client_failed_downloads mediaspot_id, mediaspot_name, client_name, failed_downloads

	  	report = {
	  		creates: 0,
	  		updates: 0
	  	}

  		failed_downloads.select{|e| e['hour'].to_i > 0 }.sort { |x,y| x['hour'].to_i <=> y['hour'].to_i }.each { |entry|

  			time = Time.at(entry['hour'].to_i * 3600).to_datetime
  			num_failures = entry['numfailures'].to_i

  			existing_entry = AnalyticsFailedDownloadsPerHour.where(
  				mediaspot_id: mediaspot_id,
  				client_name: client_name,
  				time: time,
  			).first

  			if existing_entry == nil

  				created = AnalyticsFailedDownloadsPerHour.create!(
	  				mediaspot_id: mediaspot_id,
	  				client_name: client_name,
	  				time: time,
	  				num_failures: num_failures
					)

					report[:creates] = report[:creates] + 1

					log "created: #{created.inspect}"

  			elsif existing_entry[:num_failures] != num_failures

  				existing_entry.update_attributes(
	  				num_failures: num_failures
					)

					report[:updates] = report[:updates] + 1

					log "updated: #{existing_entry.inspect}"

  			end
  		}

  		report

	  end


  	def cron_log txt
  		p Time.now.to_s + ' -- ' + txt.to_s
  		log txt
  	end


  	def log_error txt
			Rails.logger.fatal("SaveAnalyticsWorker_LOGGER ----- " + txt.to_s)
  	end

  	def log txt
			Rails.logger.info("SaveAnalyticsWorker_LOGGER ----- " + txt.to_s)
  	end

end