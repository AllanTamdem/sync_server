class SaveFileTypeForAnalyticsWorker

	# for all files or for one file: 
	# get the type of a file (video, audio, etc...) as a parameter or via the JSON metadata
	# and insert this type in mongodb attached to this file
	# so the analytics will be accurate

  include Sidekiq::Worker
	include S3v2Helper
	include ContentProvidersHelper

  sidekiq_options retry: false

	require 'json'
	require 'net/http'


  def perform_all

  	return "runs only in production" if false == (Rails.env.production? or Rails.env.test?)
  	
		cron_log "----STARTING SaveFileTypeForAnalyticsWorker"

  	get_all_s3_infos.each{|s3_info|

  		path = ''
  		
  		if s3_info[:path_in_bucket].blank? == false
  			path = s3_info[:path_in_bucket]
  		end

	  	files_result = s3_get_files(s3_info, path)

			if files_result[:error] != nil
				log_error("Couldn't get files from bucket #{s3_info}. error : #{files_result[:error]}")
			else

		  	json_files = files_result[:files].select{|f|
					f[:key].end_with?('.json') 
				}

				json_files.each{ |f|
					# resp = Net::HTTP.get_response(URI.parse(f[:url_for_read]))
					# metadata = resp.body
					metadata = s3_read_object(s3_info, f[:key])
					perform(s3_info, f[:key][0..-6], metadata[:body])
				}

			end

  	}
  	
		cron_log "----ENDING SaveFileTypeForAnalyticsWorker"

		nil

  end


  def perform(s3_info, file_key, metadata, p_type=nil)

  	type = nil

  	if p_type != nil
  		type = nil
  	else
	  	if metadata == nil
				metadata = s3_read_object(s3_info.symbolize_keys, file_key + '.json')[:body]
	  	end

	  	type = get_type(metadata)
  	end


		if type != nil and type != ''

			save_file_type(file_key, type)

		else
			log("couldn't read the type of file #{file_key} . metadata: #{metadata}")
		end

  end


  private

  	def get_type metadata

			parsed_metadata = JSON.parse(metadata)

			if parsed_metadata.key?('type') and parsed_metadata['type'] != nil

				return parsed_metadata['type']

			end

			return nil
  	end

	  def save_file_type file_key, type

			existing_entry = AnalyticsFileType.where(
				file: file_key
			).first

			if existing_entry == nil

				created = AnalyticsFileType.create!(
					file: file_key,
					type: type
				)

				log "created: #{created.inspect}"

			elsif existing_entry[:type] != type

				existing_entry.update_attributes(
					type: type
				)

				log "updated: #{existing_entry.inspect}"

			end

	  end


		def cron_log txt
			p Time.now.to_s + ' -- ' + txt.to_s
			log txt
		end


		def log_error txt
			Rails.logger.fatal("SaveFileTypeForAnalyticsWorker_LOGGER ----- " + txt.to_s)
		end

		def log txt
			Rails.logger.info("SaveFileTypeForAnalyticsWorker_LOGGER ----- " + txt.to_s)
		end



end