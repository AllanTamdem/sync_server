class SyncMediaspotWorker
  include Sidekiq::Worker

  sidekiq_options retry: false
  
  require 'date'

  include Tr069Helper
  include MediaspotHelper

  def perform device_id, client_number
  	client_number = client_number.to_s

  	log "syncing client #{client_number} on mediaspot #{device_id}"

		param_string = "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}.SyncNow"
		
		result = tr069_set_parameter_if_not_in_queue(device_id, param_string, true)
		result_refresh = tr069_refresh_client_on_device_if_not_in_queue(device_id, client_number)

		iRefreshed = 1
		iLoop = 1

		loop do 

			device = tr069_get_device(device_id)

			client = get_client(device, client_number)

			if device['connected'] == false
				log "device #{device_id}(#{device['mediaspotName']}) is offline"
				break
			end

			tasks = tr069_get_task_queue(device_id)

			if tasks.count == 0
				if client['syncing'] == false
					if iLoop > 5
						# We loop at least 5 times to make sure it's really finished
						break # Exit the loop. End of syncing!
					end
				else
					tr069_refresh_client_on_device_if_not_in_queue(device_id, client_number)
					iRefreshed = iRefreshed + 1
					log "#{device_id}(#{device['mediaspotName']}) has no tasks but is still syncing so we refresh it"
				end
			else
				log "#{device_id}(#{device['mediaspotName']}).#{client['name']} is syncing"
			end
			sleep(2)
			iLoop = iLoop + 1
		end

  	log "finished syncing client #{client_number} on mediaspot #{device_id} (refreshed #{iRefreshed} times)"
  end


  private

  	def get_client device, client_number

		if device == nil
			return nil
		end

		if device.key?('InternetGatewayDevice') and
			device['InternetGatewayDevice'].key?('X_orange_tapngo') and
			device['InternetGatewayDevice']['X_orange_tapngo'].key?('Clients') and
			device['InternetGatewayDevice']['X_orange_tapngo']['Clients'].key?(client_number)

			client = device['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number]

			mediaspot_set_ziped_value(client, 'RepoSyncLog')
			mediaspot_set_syncing_status(client)

			client['name'] = 'No name'

			if client.include?('ClientName') and client['ClientName'].include?('_value')
				client['name'] = client['ClientName']['_value']
			end

			return client
		end
  		
  		nil
  	end

  	def log txt
  		p Time.now.to_s + " -- " + txt
  	end

end