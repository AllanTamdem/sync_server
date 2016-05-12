module Tr069Helper

	require 'net/http'
	require 'json'

	include ActionView::Helpers::DateHelper

	include WebsocketHelper

	@@api_host = Rails.configuration.tr069_api_host
	@@api_port = Rails.configuration.tr069_api_port


	def tr069_get_devices
		url = 'http://' + @@api_host + ':' + @@api_port.to_s + '/devices'

		resp = Net::HTTP.get_response(URI.parse(url))
		json = resp.body

		devices = JSON.parse(json)
		ws_devices = websocket_get_mediaspots

		fill_device_info(devices, ws_devices)

		devices
	end

	def tr069_get_device device_id

		url = 'http://' + @@api_host + ':' + @@api_port.to_s + "/devices/?query=%7B%22_id%22%3A%22#{device_id}%22%7D" #query={"_id":"{device_id}"}

		resp = Net::HTTP.get_response(URI.parse(url))

		devices = JSON.parse(resp.body)
		ws_devices = websocket_get_mediaspots		

		fill_device_info(devices, ws_devices)

		devices.first
	end


	def tr069_get_task_queue device_id

		url = 'http://' + @@api_host + ':' + @@api_port.to_s + "/tasks?query=%7B%22device%22%3A%22#{device_id}%22%7D"

		resp = Net::HTTP.get_response(URI.parse(url))
		
		JSON.parse(resp.body)
	end	


	def tr069_get_task_queue_all

		url = 'http://' + @@api_host + ':' + @@api_port.to_s + "/tasks"

		resp = Net::HTTP.get_response(URI.parse(url))

		JSON.parse(resp.body)
	end


	# def tr069_refresh_synclog device_id, client_number
	# 	tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}.RepoSyncLog"})
	# end

	def tr069_wake_up_device device_id
		websocket_wake_up_mediaspot(device_id)
	end

	def tr069_reboot_device device_id
		tr069_post(device_id, {'name' => 'reboot'})
		tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => ""})
		websocket_wake_up_mediaspot(device_id)
	end


	def tr069_refresh_device device_id
		tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => ""})
		websocket_wake_up_mediaspot(device_id)
	end

	# send a task to refresh the mediaspot
	# only if there's not already a refresh task
	def tr069_refresh_device_if_not_in_queue device_id

		tasks = tr069_get_task_queue(device_id)

		is_in_queue = tasks.any?{ |t|
			t['name'] == 'refreshObject' and t['device'] == device_id	and
			t['objectName'] == ""
		}

		if !is_in_queue
			tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => ""})
			websocket_wake_up_mediaspot(device_id)
		end
	end
	


	def tr069_refresh_client_on_device device_id, client_number
		tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}"})
		websocket_wake_up_mediaspot(device_id)
	end


	def tr069_refresh_client_on_device_if_not_in_queue device_id, client_number

		tasks = tr069_get_task_queue(device_id)

		is_in_queue = tasks.any?{ |t|
			t['name'] == 'refreshObject' and t['device'] == device_id	and
			t['objectName'] == "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}"
		}

		if !is_in_queue
			tr069_post(device_id, {'name' => 'refreshObject', 'objectName' => "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}"})
			websocket_wake_up_mediaspot(device_id)
		end

	end

	# not use anymore, because we refresh the whole device instead
	# def tr069_get_parameter device_id, name
	# 	post(device_id, {'name' => 'getParameterValues', 'parameterNames' => [name]})
	# end

	def tr069_set_parameter device_id, name, value

		tr069_post(device_id, {'name' => 'setParameterValues', 'parameterValues' => [[name, value]]})
	end

	# only set the parameter if the same parameter is not already in the queue
	def tr069_set_parameter_if_not_in_queue device_id, name, value

		tasks = tr069_get_task_queue(device_id)

		is_in_queue = tasks.any?{ |t|
			t['parameterValues'].is_a?(Array) and t['parameterValues'][0].is_a?(Array) and
			t['parameterValues'][0][0] == name and t['parameterValues'][0][1].to_s == value.to_s
		}

		if !is_in_queue
			tr069_post(device_id, {'name' => 'setParameterValues', 'parameterValues' => [[name, value]]})
		end
	end
	

	def tr069_delete_device device_id
		http = Net::HTTP.new(@@api_host, @@api_port)
		res = http.delete("/devices/#{device_id}")

		{
			code: res.code,
		 	message: res.message,
			body: res.body
		}	
	end


	def tr069_delete_task task_id
		http = Net::HTTP.new(@@api_host, @@api_port)
		res = http.delete("/tasks/#{task_id}/")

		{
			code: res.code,
		 	message: res.message,
			body: res.body
		}	
	end

	private

		def tr069_post device_id, task
			http = Net::HTTP.new(@@api_host, @@api_port)
			res = http.post("/devices/#{device_id}/tasks?connection_request", ActiveSupport::JSON.encode(task))

			{
				code: res.code,
			 	message: res.message,
				body: res.body
			}
		end

		def fill_device_info devices, ws_devices
			devices.each{ |device|

				device['_id'] = URI.unescape(device['_id'])

				ws_device = ws_devices.find{|ws_device|
					ws_device['mediaspot_id'] == device['_id'] || 
					URI.unescape(ws_device['mediaspot_id']) == device['_id']
				}

				device['websocket'] = ws_device != nil

				populate_last_inform_info(device, ws_device)

				if device.include?('InternetGatewayDevice') and
					device['InternetGatewayDevice'].include?('X_orange_tapngo') and
					device['InternetGatewayDevice']['X_orange_tapngo'].include?('MediaspotName') and
					device['InternetGatewayDevice']['X_orange_tapngo']['MediaspotName'].include?('_value') and
					device['InternetGatewayDevice']['X_orange_tapngo']['MediaspotName']['_value'].blank? == false

					device['mediaspotName'] = device['InternetGatewayDevice']['X_orange_tapngo']['MediaspotName']['_value']
				else
					device['mediaspotName'] = device['_id']
				end

				device['date_updated'] = device['InternetGatewayDevice']['_timestamp']

				if device['date_updated'] != nil
					device['date_updated_ago'] = time_ago_in_words(device['date_updated'], include_seconds: true) + ' ago'
				end
			}

			devices
		end

		def populate_last_inform_info tr_device, ws_device

			tr_lastinform = (tr_device['summary.lastInform']).to_datetime
			ws_lastinform = nil

			lastinform = nil
			ago = nil
			connected = false

			if ws_device.nil? == false
				ws_lastinform = (ws_device['lastinform']).to_datetime
			end

			if ws_lastinform.nil? or tr_lastinform > ws_lastinform 
				lastinform = tr_lastinform
			else 
				lastinform = ws_lastinform
			end

			if ws_device.nil?
				connected = time_ago_in_seconds(lastinform) < 31*60 # 31mn with TR69
			else
				connected = time_ago_in_seconds(lastinform) < 6*60 # 6mn with websocket
			end

			tr_device['connected'] = connected
			tr_device['date_last_inform'] = lastinform
			tr_device['date_last_inform_tr'] = tr_lastinform
			tr_device['date_last_inform_ws'] = ws_lastinform
			tr_device['date_last_inform_ago'] = time_ago_in_words(lastinform, include_seconds: true) + ' ago'

		end


		def time_ago_in_seconds date
			return ((DateTime.now - date)  * 24 * 60 * 60).to_i
		end

end