

# otherwise, each cron task will run this as well
if !Rails.const_defined?('Console')

	redis_sub = Redis::Namespace.new(Rails.configuration.tr069_pubsub_scope,
		redis: Redis.new(host: Rails.configuration.tr069_pubsub_host,
			port: Rails.configuration.tr069_pubsub_port,
			driver: :hiredis))

	Thread.new do

		begin
			redis_sub.subscribe('tasks_inserts', 'tasks_remove', 'tasks_update') do |on|
				Rails.logger.info('tr069_redis_pubsub subscribed')
			  on.message do |redis_channel, message|

			  	websocket_channel = redis_channel.gsub("#{Rails.configuration.tr069_pubsub_scope}:","")	  	
			  	WebsocketRails[:tr069].trigger(websocket_channel, message)

			  	
					Rails.logger.info("tr069_redis_pubsub message received. channel #{redis_channel}. message #{message}")
			  end
			end
		rescue Redis::BaseConnectionError => error
			Rails.logger.fatal("tr069_redis_pubsub error. #{error}. Retrying in 5s")
			# we end up here if the tr069 server is rebooted.
			# so we restart the subscribe after 5 seconds
		  sleep 5
		  retry
		end

	end

end
