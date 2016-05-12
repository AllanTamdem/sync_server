class LabgencyApplyCidWorker
  
	require 'date'

	include S3v2Helper
	include ContentProvidersHelper

	def perform
  	return "runs only in production" if false == (Rails.env.production? or Rails.env.test?)

		source = 'labgency/'
		destination = 'mediatransport-labgency/.staging/'

		files_processed = []

		log "----STARTING LabgencyApplyCidWorker"

		log "files in #{source} : "
		files_result = s3_get_files(get_default_s3_info, "#{source}")

		files = files_result[:files].select{|f|
			!f[:key].end_with?('.json')
		}

		files.each{ |f|
			log f[:key]
		}

		if files.size == 0
			log 'no files to process'
		else
  		log "Labgency's catalog :"
			url = Rails.configuration.labgency_api
			resp = Net::HTTP.get_response(URI.parse(url))
			labgency_catalog_json =  resp.body

			# log labgency_catalog_json

			labgency_catalog = JSON.parse(labgency_catalog_json)

			files.each{ |f|

				labgency_catalog.each{ |c|

					if f[:key].start_with?("#{source}#{c['vid']}/")

						new_key = destination + f[:key][(source.length..-1)]

						log "moving file from #{f[:key]} to #{new_key}"

						if s3_exists?(get_default_s3_info, new_key)
							log "the file #{new_key} already exists and is going to be replaced"
						end

						s3_move_file(get_default_s3_info, f[:key], new_key)

						key_metadata = new_key + '.json'

						metadata_json = '{"validationPlatform": "labgency", "validationPlatformData":{"cid": "' + c['cid'] + '"}}'

						if s3_exists?(get_default_s3_info, key_metadata)
							log "the metadata file #{key_metadata} already exists and is going to be replaced"
						end

						log "creating metadata file #{key_metadata} with #{metadata_json}"

						s3_put_file(get_default_s3_info, key_metadata, metadata_json)

						files_processed << {file: f[:key][(source.length..-1)], cid: c['cid']}

					end
				}
			}

			log 'files processed :'

			log files_processed.to_yaml
		end

		log files_processed.to_yaml

		content = files_processed.length.to_s + ' files processed'
		if files_processed.size > 0
			content += files_processed.to_yaml			
			create_log(content)
		end


		log "----ENDING LabgencyApplyCidWorker"

		return content
  end

  private

  	def log txt
  		p Time.now.to_s + ' -- ' + txt.to_s
  	end

		def create_log  content
			
	  	ApplicationLog.create!(
				time: Time.now,
				user: 'BATCH',
				action_type: ApplicationLog::Action_type_repo,
	      action: 'BATCH_LABGENCY_SET_CID',
				details: content
			)

		end

end