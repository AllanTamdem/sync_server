class RefreshMediaspotsWorker
  
  require 'date'

  include Tr069Helper

  def perform
  	return "runs only in production" if false == Rails.env.production?

		p Time.now.to_s + " -- " + "----STARTING RefreshMediaspotsWorker"

		devices = tr069_get_devices()

		devices.each{ |device|
			if device['connected']
  			p  Time.now.to_s + " -- refreshing " + device['mediaspotName']
				tr069_refresh_device_if_not_in_queue(device['_id'])
			else
  			p Time.now.to_s + " -- " + device['mediaspotName'] + " is offline"
			end
		}

		p Time.now.to_s + " -- " + "----ENDING RefreshMediaspotsWorker"
  end

end