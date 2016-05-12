module MediaspotHelper

	def mediaspot_set_ziped_value obj, key
		if obj.include?(key) and obj[key].include?('_value') and obj[key]['_value'] != ''
			begin
				obj[key]['_value'] = ActiveSupport::Gzip.decompress(Base64.decode64(obj[key]['_value']))
			rescue
				obj[key]['_value'] = ''
			end
		end
	end


	def mediaspot_set_value obj, key
		if obj.include?(key) and obj[key].include?('_value') and obj[key]['_value'] != ''
			begin
				obj[key]['_value'] = obj[key]['_value']
			rescue
				obj[key]['_value'] = ''
			end
		end
	end


	# set information about the syncing status
	def mediaspot_set_syncing_status client

		# time since last sync
		client['synced_ago'] = nil
		client['synced_date'] = nil
		begin
			repoSyncLastCompletedTime = client['RepoSyncLastCompletedTime']['_value']
			if repoSyncLastCompletedTime != '' and repoSyncLastCompletedTime != 'No Info'
				client['synced_ago'] = time_ago_in_words(repoSyncLastCompletedTime, include_seconds: true) + ' ago'
				client['synced_date'] = repoSyncLastCompletedTime
			end
		rescue
		end

		log = ''
		begin
			log = client['RepoSyncLog']['_value']
		rescue
		end

		# is it syncing now?
		client['syncing'] = false

		if client.key?('IsSyncing') and client['IsSyncing'].key?('_value')

			client['syncing'] = client['IsSyncing']['_value'] == 'true' or
				client['IsSyncing']['_value'] == true or
				client['IsSyncing']['_value'] == 'stuck'
				
		else
			unless (log||'').strip == '' or
				log.lines.last.include?('ERROR:') or
				log.lines.last.include?('error:') or
				log.lines.any?{|line| line.start_with?('Done.') or line.start_with?('INFO: Done.') }
				client['syncing'] = true
			end
		end


		# were there an error?
		client['sync_error'] = false
		begin
			lastLine = log.split("\n").last
			if lastLine.include?('ERROR:') or
				lastLine.include?('error:')
				client['sync_error'] = true
			end
		rescue
		end

	end

	def mediaspot_get_client_name_by_number mediaspot, client_number

		mediaspot_get_clients(mediaspot).each{ |client|

			if client_number == client['client_number'] and
				client.include?('ClientName') and
				client['ClientName'].include?('_value')

					return client['ClientName']['_value']

			end
		}

		nil

	end

	def mediaspot_get_clients_names mediaspot

		client_names = []

		mediaspot_get_clients(mediaspot).each{ |client|			
			if client.include?('ClientName') and client['ClientName'].include?('_value')
				client_names << client['ClientName']['_value']
			end
		}

		client_names

	end

	def extract_system_info system_info

		result = { memory_used_percent: nil, swap_used_percent: nil }

    memory_line = system_info.lines.find{|l| l.start_with?('KiB Mem' )}
    if memory_line != nil
    	memory_total_match = /(\d+) total/.match(memory_line)
    	memory_used_match = /(\d+) used/.match(memory_line)

    	if memory_total_match != nil and memory_used_match != nil
		    memory_total = memory_total_match[1].to_f
		    memory_used = memory_used_match[1].to_f
	    	result[:memory_used_percent] = (memory_used / memory_total * 100).round(2)

	    	real_free_ram_match = /Free RAM \(KiB\): (\d+)/.match(system_info)
	    	if real_free_ram_match != nil
	    		real_free_ram = real_free_ram_match[1].to_f
	    		result[:memory_used_percent] = ((memory_total - real_free_ram) / memory_total * 100).round(2)
	    	end

    	end	
    end

    swap_line = system_info.lines.find{|l| l.start_with?('KiB Swap' )}
    if swap_line != nil
    	swap_total_match = /(\d+) total/.match(swap_line)
    	swap_used_match = /(\d+) used/.match(swap_line)

    	if swap_total_match != nil and swap_used_match != nil
		    swap_total = swap_total_match[1].to_f
		    swap_used = swap_used_match[1].to_f
		    if swap_total > 0
		    	result[:swap_used_percent] = (swap_used / swap_total * 100).round(2)
		    else
		    	result[:swap_used_percent] = 0
		    end
    	end	
    end

    return result

	end



	def mediaspot_get_clients mediaspot

		clients = []

		if mediaspot.key?('InternetGatewayDevice') and
				mediaspot['InternetGatewayDevice'].key?('X_orange_tapngo') and
				mediaspot['InternetGatewayDevice']['X_orange_tapngo'].key?('Clients')

				mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'].keys.each do |client_number|

					if ["_object", "_writable", "_timestamp"].include?(client_number) == false

						client = mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number].clone

						client['client_number'] = client_number
						client['client_name'] = client['ClientName']['_value']
						client['mediaspot_id'] = mediaspot['_id']
						client['mediaspot_name'] = mediaspot['mediaspotName']

						clients << client

					end

				end
		end

		clients

	end

end