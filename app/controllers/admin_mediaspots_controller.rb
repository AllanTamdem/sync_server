class AdminMediaspotsController < ApplicationController	

	require 'active_support/gzip'
	include ActionView::Helpers::DateHelper	
	include Tr069Helper
	include MediaspotHelper
	include ContentProvidersHelper
	include SiteSettingsHelper
	include WorkersHelper

	before_action :authenticate_user!
	before_action do
		unless current_user.try(:admin?)
		  redirect_to root_path
		end
	end

	def index

		@default_bucket = Rails.configuration.aws_bucket
		
		@tr069_hosts_white_list = (sites_settings_tr069_hosts_white_list || '').split(',').map{|x| x.strip }

		@websocket_hosts_white_list = (sites_settings_websocket_hosts_white_list || '').split(',').map{|x| x.strip }

	end

	def add_client

		client_name = params['client-name']
		device_id = params['device-id']

		device = tr069_get_device(device_id)

		if device['InternetGatewayDevice']['X_orange_tapngo'].key?('ClientAddByNameAndRepoCredentials')

			s3_info = get_content_provider_s3_info(client_name)
			cp = get_content_provider_by_technical_name(client_name)

			json_parameter = {
				clientname: client_name,
				accesskey: s3_info[:aws_bucket_access_key_id],
				secretkey: s3_info[:aws_bucket_secret_access_key],
				hostbase: s3_info[:aws_bucket_host],
				bucketname: s3_info[:aws_bucket_name],
				dounzipping: cp[:unzipping_files].blank? ? 'No' : cp[:unzipping_files],
				pathinbucket: cp[:path_in_bucket].blank? ? client_name : cp[:path_in_bucket]
			}.to_json

			base64_parameter = Base64.encode64(json_parameter)

			tr069_set_parameter(device_id, 'InternetGatewayDevice.X_orange_tapngo.ClientAddByNameAndRepoCredentials', base64_parameter)

		else
			tr069_set_parameter(device_id, 'InternetGatewayDevice.X_orange_tapngo.ClientAddByName', client_name)
		end

		result_refresh = tr069_refresh_device(device_id)

		save_tr069_log(current_user.email, 'add_client',
			{
				client_name: client_name,
				device_id: device_id
			}.to_json)

		render :json => { result: nil }
	end



	def remove_client

		client_name = params['client-name']
		device_id = params['device-id']

		# Thread.new do
			result = tr069_set_parameter(device_id, 'InternetGatewayDevice.X_orange_tapngo.ClientRemoveByName', client_name)
			result_refresh = tr069_refresh_device(device_id)
		# end

		save_tr069_log(current_user.email, 'remove_client',
			{
				client_name: client_name,
				device_id: device_id
			}.to_json)

		render :json => { result: nil }
	end



	def set_client_parameter

		result = { result: nil }

		device_id = params['device-id']
		client_number = params['client-number']
		parameter_name = params['parameter-name']
		parameter_value = params['parameter-value']

		if parameter_name == 'SyncNow'
			result = sync_if_needed(device_id, client_number)

			if result[:processing] == true
				save_tr069_log(current_user.email, 'set_client_parameter',
					{
						device_id: device_id,
						client_number: client_number,
						parameter_name: parameter_name,
						parameter_value: parameter_value
					}.to_json)
			end

		else
			param_string = "InternetGatewayDevice.X_orange_tapngo.Clients.#{client_number}.#{parameter_name}"

			result = tr069_set_parameter(device_id, param_string, parameter_value)
			result_refresh = tr069_refresh_client_on_device(device_id, client_number)

			if parameter_name == 'MakeAnalyticsNow'
				SaveAnalyticsWorker.perform_in(31.seconds, device_id, client_number)
			end

			save_tr069_log(current_user.email, 'set_client_parameter',
				{
					device_id: device_id,
					client_number: client_number,
					parameter_name: parameter_name,
					parameter_value: parameter_value
				}.to_json)

		end

		render :json => result
	end


	def set_mediaspot_internet_white_list

		device_id = params['device_id']
		internet_white_list = params['internet_white_list']

		encoded_internet_white_list = Base64.encode64(ActiveSupport::Gzip.compress(internet_white_list))

		result = tr069_set_parameter(device_id, "InternetGatewayDevice.X_orange_tapngo.InternetWhitelist", encoded_internet_white_list)
		result_refresh = tr069_refresh_device(device_id)

		save_tr069_log(current_user.email, 'set_mediaspot_internet_white_list',
		{
			device_id: device_id,
			internet_white_list: internet_white_list
		}.to_json)

		render :json => { result: nil }
	end


	def set_mediaspot_custom_info

		device_id = params['device_id']
		custom_info = params['custom_info']

		begin
			JSON.parse(custom_info)
		rescue
			render :json => { result: nil, error: 'The JSON is invalid' }
			return
		end

		encoded_custom_info = Base64.encode64(ActiveSupport::Gzip.compress(custom_info))

		result = tr069_set_parameter(device_id, "InternetGatewayDevice.X_orange_tapngo.MediaspotCustomInfo", encoded_custom_info)
		result_refresh = tr069_refresh_device(device_id)

		save_tr069_log(current_user.email, 'set_mediaspot_custom_info',
		{
			device_id: device_id,
			custom_info: custom_info
		}.to_json)

		render :json => { result: nil }
	end


	def set_mediaspot_internet_blocking_enabled

		device_id = params['device_id']
		internet_blocking_enabled = params['internet_blocking_enabled']

		result = tr069_set_parameter(device_id, "InternetGatewayDevice.X_orange_tapngo.InternetBlockingEnabled", internet_blocking_enabled)
		result_refresh = tr069_refresh_device(device_id)

		save_tr069_log(current_user.email, 'set_mediaspot_internet_blocking_enabled',
		{
			device_id: device_id,
			internet_blocking_enabled: internet_blocking_enabled
		}.to_json)

		render :json => { result: nil }
	end


	def set_mediaspot_wifi_setting

		device_id = params['device-id']
		interfac = params['interfac']
		key = params['key']
		value = params['value']

		tr069_set_parameter(device_id, "InternetGatewayDevice.X_orange_tapngo.Wifis.#{interfac}.#{key}", value)
		tr069_wake_up_device(device_id)
		
		RefreshMediaspotWorker.perform_in(15.seconds, device_id)

		save_tr069_log(current_user.email, 'set_mediaspot_wifi_setting',
			{
				device_id: device_id,
				interface: interfac,
				key: key,
				value: value
			}.to_json)

		render :json => { result: nil }
	end


	def refresh_all

		device_id = params['device-id']

		# Thread.new do
			result_refresh = tr069_refresh_device(device_id)
		# end

		render :json => { result: nil }
	end
	

	def get_task_queue
		device_id = params['device-id']

		response = tr069_get_task_queue(device_id)

		render :json => {device_id: device_id, tasks: response}
	end
	

	def get_all_tasks
		tasks = tr069_get_task_queue_all

		render :json => {tasks: tasks}
	end


	def delete_mediaspot

		device_id = params['device-id']

		result = tr069_delete_device(device_id)

		save_tr069_log(current_user.email, 'delete_mediaspot',
		{
			device_id: device_id
		}.to_json)

		render :json => { result: result }
	end


	def delete_mediaspot_tasks
		exec_async {
			device_id = params['device-id']

			tasks = tr069_get_task_queue(device_id)

			result = []

			tasks.each{|t|
				result << tr069_delete_task(t['_id'])
			}

			save_tr069_log(current_user.email, 'delete_mediaspot_tasks',
			{
				device_id: device_id
			}.to_json)

			render :json => { result: result }
		}
	end


	def reboot_mediaspot

		device_id = params['device-id']

		result = tr069_reboot_device(device_id)

		save_tr069_log(current_user.email, 'reboot_mediaspot',
		{
			device_id: device_id
		}.to_json)
			
		render :json => { result: result }
	end


	def set_mediaspot_parameter

		result = tr069_set_parameter(params[:mediaspot_id], "InternetGatewayDevice.X_orange_tapngo.#{params[:key]}", params[:value])
		result_refresh = tr069_refresh_device(params[:mediaspot_id])

		save_tr069_log(current_user.email, "set_mediaspot_parameter",
			{
				mediaspot_id: params[:mediaspot_id],
				key: params[:key],
				value: params[:value]
			}.to_json)

		render :json => { result: nil }
	end


	def get_mediaspots

		mediaspots = tr069_get_devices

		result_mediaspots = []

		content_providers = ContentProvider.all

		mediaspots.each{ |mediaspot|

			result_mediaspot = {}
			result_mediaspot['details'] = mediaspot
			result_mediaspot['DT_RowId'] = 'row_' + mediaspot['_id']

			clients = []
			listClientsNames = []

			# list of clients
			if mediaspot.key?('InternetGatewayDevice') and
				mediaspot['InternetGatewayDevice'].key?('X_orange_tapngo') and
				mediaspot['InternetGatewayDevice']['X_orange_tapngo'].key?('Clients')

				mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'].keys.each do |client_number|

					if ["_object", "_writable", "_timestamp"].include?(client_number) == false

						client = mediaspot['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number].clone
						client['number'] = client_number
						clientName = 'No name'
						content_provider = nil

						if client.include?('ClientName') and client['ClientName'].include?('_value')
							clientName = client['ClientName']['_value']
							content_provider = content_providers.find{ |cp|
								cp.technical_name == clientName
							}
						end

						mediaspot_set_ziped_value(client, 'DownloadAccessLog')
						mediaspot_set_ziped_value(client, 'DownloadAnalytics')
						mediaspot_set_ziped_value(client, 'RepoSyncLog')
						mediaspot_set_ziped_value(client, 'IndexJson')

						mediaspot_set_syncing_status(client)

						client['content_provider'] = content_provider

						if content_provider == nil
							client['name'] = '<i>' + clientName + '</i>'
						else
							client['name'] = '<b>' + content_provider.name + '</b>'
						end

						listClientsNames << client['name']

						clients << client
					end
				end
			end

			result_mediaspot['Log'] = ''
			if mediaspot.key?('InternetGatewayDevice') &&
				mediaspot['InternetGatewayDevice'].key?('X_orange_tapngo')

				result_mediaspot['Log'] = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'Log')
				result_mediaspot['SystemMonitor'] = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'SystemMonitor')
				result_mediaspot['InternetWhitelist'] = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'InternetWhitelist')
				result_mediaspot['InternetBlockingEnabled'] = mediaspot_set_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'InternetBlockingEnabled')
				result_mediaspot['SystemInfo'] = extract_system_info(result_mediaspot['SystemMonitor'])
				result_mediaspot['MediaspotCustomInfo'] = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'MediaspotCustomInfo')
				result_mediaspot['WifiSurvey'] = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'WifiSurvey')
			end


			result_mediaspot['clients'] = clients
			result_mediaspot['listClientsNames'] = listClientsNames.sort.join(', ')

			result_mediaspots << result_mediaspot
		}

		render :json => { data: result_mediaspots}

	end

end