module WebsocketHelper

	@@base_url = Rails.configuration.node_ws_api


	def websocket_wake_up_mediaspot mediaspot_id

		if is_mediaspot_connected(mediaspot_id) == false
			return false
		end

		query = "?message=INFORMREQUEST&mediaspot_id=#{mediaspot_id}"

		resp = Net::HTTP.get_response(URI.parse(@@base_url + query))

		if resp.code_type == Net::HTTPOK
			return true
		end

		if resp.code_type == Net::HTTPNotFound			
			Rails.logger.info("WebsocketHelper " + resp.to_yaml)
			return false
		end

		Rails.logger.fatal("WebsocketHelper " + resp.to_yaml)
		return false

	end

	def websocket_get_mediaspots

		resp = Net::HTTP.get_response(URI.parse(@@base_url + '/mediaspots'))

		JSON.parse(resp.body)

	end

	def websocket_is_mediaspot_connected mediaspot_id

		return is_mediaspot_connected(mediaspot_id)

	end

	private

		def is_mediaspot_connected mediaspot_id
			
			return nil != websocket_get_mediaspots.find{|ws_device|
				ws_device['mediaspot_id'] == mediaspot_id
			}

		end




end