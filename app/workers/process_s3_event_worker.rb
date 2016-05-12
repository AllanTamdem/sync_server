class ProcessS3EventWorker
  include Sidekiq::Worker

  include ContentProvidersHelper
	include Tr069Helper
	include PathHelper
  include WorkersHelper

  sidekiq_options retry: false

  def perform sqs_json_message

  	process_message(JSON.parse(sqs_json_message))

  end
  

	def process_message message

		message['Records'].each{|record|

			bucket = record['s3']['bucket']['name']
			file = record['s3']['object']['key']

			if record['eventName'].start_with?('ObjectCreated')
				log_message(
					'upload_complete',
					{
						file: file,
						file_size: record['s3']['object']['size'],
						bucket: bucket
					})

				trigger_sync_if_needed(bucket, file)

			end

			if record['eventName'].start_with?('ObjectRemoved')
				log_message(
					'delete_files',
					{
						bucket: bucket,
						deleted_files: [file]
					})
			end
		}

	end

	def trigger_sync_if_needed bucket, file

		content_providers = find_content_providers_by_bucket_and_file(bucket, file)

		mediaspots = tr069_get_devices

		content_providers.each{ |cp|
			cp_path_in_bucket = cp[:path_in_bucket]
			if cp_path_in_bucket.blank?
				cp_path_in_bucket = cp[:technical_name]
			end

			path_in_bucket = path_prettify(cp_path_in_bucket)

			if file.start_with?(path_in_bucket + '.staging/') ||
				file.start_with?(path_in_bucket.gsub(' ','+') + '.staging/') ||
				file.start_with?(path_in_bucket.gsub(' ','%20') + '.staging/')

				# no need to do anything here.
				# files in .staging don't need to be synced
			else

				mediaspots.each{|mediaspot|

					if mediaspot.include?('InternetGatewayDevice') and
						mediaspot['InternetGatewayDevice'].include?('X_orange_tapngo') and
						mediaspot['InternetGatewayDevice']['X_orange_tapngo'].include?('Clients')

						mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'].keys.each { |client_number|

							if ["_object", "_writable", "_timestamp"].include?(client_number) == false

								client = mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number]

								if client.include?('ClientName') and client['ClientName'].include?('_value')
									client_name = client['ClientName']['_value']

									if client_name == cp[:technical_name]

  									if Rails.env.production?
											Rails.logger.info("S3 event triggered syncing: #{mediaspot['_id']}. client: #{client_number} (#{client_name})")
											# SyncMediaspotWorker.perform_async(mediaspot['_id'], client_number)
											sync_if_needed(mediaspot['_id'], client_number)
										end

									end

								end
							end
						}

					end
				}

			end
		}

	end

	# Save in System Logs
	def log_message event_type, details

		SaveApplicationLogWorker.perform_async(
			Rails.configuration.aws_sqs_s3_events,
			ApplicationLog::Action_type_repo,
			event_type,details.to_json)

	end


end
