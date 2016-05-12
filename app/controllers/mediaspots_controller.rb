class MediaspotsController < ApplicationController

	before_action :authenticate_user!

	include Tr069Helper
	include PathHelper
	include MediaspotHelper
	include UsersHelper
	include ContentProvidersHelper
	include WorkersHelper

	def index

		user_content_providers = user_get_content_providers(current_user)

		@content_providers = []

		user_content_providers.each{ |cp|
			@content_providers << {technical_name: cp.technical_name, name: cp.name}
		}

		# @mediaspots = ActiveSupport::JSON.encode(private_get_mediaspots)

	end


	def get_mediaspots

		cp = get_content_provider_by_technical_name(params['client'])

		if cp == nil
			render :json => {
				mediaspots: [],
				path_in_bucket: ''
			}

		else

			path_in_bucket = cp[:path_in_bucket]

			if path_in_bucket.blank?
				path_in_bucket = cp[:technical_name]
			end

			render :json => {
				mediaspots: private_get_mediaspots(params['client']),
				path_in_bucket: path_in_bucket
			}

		end
		
	end

	def set_client_parameter

		result = { result: nil  }

		device_id = params['device-id']
		client_number = params['client-number']

		if false == can_set_parameter?(device_id, client_number)
			render json: {error: "Unauthorized"}, status: :unauthorized
			return
		end

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

			# Thread.new do
				result = tr069_set_parameter(device_id, param_string, parameter_value)
				result_refresh = tr069_refresh_client_on_device(device_id, client_number)
			# end

			if parameter_name == 'MakeAnalyticsNow'
				SaveAnalyticsWorker.perform_in(61.seconds, device_id, client_number)
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


	def get_task_queue

		clients = params['clients'] || []

		all_tasks = tr069_get_task_queue_all

		clients.each{ |client|

			client['tasks'] = []

			all_tasks.each{ |task|
				if client['mediaspot_id'] == task['device']
					if task.key?('objectName') and
						task['objectName'].include?(".Clients.#{client['client_number']}")
						client['tasks'] << task
					elsif task.key?('parameterValues') and		
						task['parameterValues'].is_a?(Array) and
						task['parameterValues'][0].is_a?(Array) and
						task['parameterValues'][0][0].include?(".Clients.#{client['client_number']}")

						client['tasks'] << task
					end
				end
			}
		}


		render :json => {clients: clients}
	end

	private

		def can_set_parameter? device_id, client_number
			if current_user.admin?
				return true
			else

				mediaspot = tr069_get_device(device_id)

				client_name = mediaspot_get_client_name_by_number(mediaspot, client_number)

				return (client_name != nil and user_can_see_client?(current_user, client_name))

			end
		end

		def private_get_mediaspots param_client

			mediaspots = tr069_get_devices

			mediaspots_mini = []

			mediaspots.each{ |m|

				# list of clients
				if m.key?('InternetGatewayDevice') and
					m['InternetGatewayDevice'].key?('X_orange_tapngo') and
					m['InternetGatewayDevice']['X_orange_tapngo'].key?('Clients')

					m['InternetGatewayDevice']['X_orange_tapngo']['Clients'].keys.each do |client_number|


						if ["_object", "_writable", "_timestamp"].include?(client_number) == false

							client = m['InternetGatewayDevice']['X_orange_tapngo']['Clients'][client_number]
							client_name = client['ClientName']['_value']

							if param_client == client_name and user_can_see_client?(current_user, client_name)

								mediaspot_set_ziped_value(client, 'RepoSyncLog')
								mediaspot_set_ziped_value(client, 'IndexJson')
								mediaspot_set_syncing_status(client)

								mediaspot_name = m['mediaspotName']
								mediaspot_id = m['_id']

								contents_tree = get_value(client, 'ContentsTree') || ""

								contents_tree = (contents_tree.split("\n")[1..-1] || []).join("\n")

								analytics_last_made_time = get_value(client, 'AnalyticsLastMadeTime')
								analytics_last_made_time_ago = nil

								if analytics_last_made_time != nil
									begin
										analytics_last_made_time_ago = 
											time_ago_in_words(analytics_last_made_time, include_seconds: true) + ' ago'
									rescue
									end
								end
								

								mediaspots_mini << {
									mediaspot_id: mediaspot_id,
									mediaspot_name: mediaspot_name,
									online: m['connected'],
									date_last_inform: m['date_last_inform'],
									date_last_inform_ago: m['date_last_inform_ago'],							
									client_name: client_name,
									client_number: client_number,
									download_enabled: get_value(client, 'DownloadEnabled') || false,
									analytics: get_zipped_value(client, 'DownloadAnalytics'),
									contents_tree: contents_tree,
									synced_ago: client['synced_ago'],
									synced_date: client['synced_date'],
									date_updated: m['date_updated'],
									date_updated_ago: m['date_updated_ago'],
									analytics_last_made_time: analytics_last_made_time,
									analytics_last_made_time_ago: analytics_last_made_time_ago,
									syncing: client['syncing'],
									sync_error: client['sync_error'],
									sync_log: get_value(client, 'RepoSyncLog') || false,
									is_syncing: get_value(client, 'IsSyncing') || nil,
									index_json: get_value(client, 'IndexJson') || '',
									sync_status: nil
								}
							end

						end

					end
				end



			}

			mediaspots_mini
		end

		def get_value obj, key
			if obj.key?(key) and obj[key].key?('_value')
				return obj[key]['_value']
			else
				return nil
			end
		end

		def get_zipped_value obj, key
			if obj.key?(key) and obj[key].key?('_value') and obj[key]['_value'] != ''
				return ActiveSupport::Gzip.decompress(Base64.decode64(obj[key]['_value']))
			else
				return nil
			end
		end


end
