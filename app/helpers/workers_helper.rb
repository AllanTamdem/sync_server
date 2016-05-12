module WorkersHelper


	# gets sidekiq status
	def workers_get_all_raw
		workers = {
			running_count: 0,
			queued_count: 0,
			running: [],
			queued: []
		}

		Sidekiq::Workers.new.each do |process_id, thread_id, work|
			workers[:running] << [process_id, thread_id, work]
		end

		Sidekiq::Queue.new.each do |job|
			workers[:queued] << job
		end

		workers[:running_count] = workers[:running].count
		workers[:queued_count] = workers[:queued].count

		workers
	end


	# start a synchronization on the mediaspot only if there's not already one processing or in the queue
	def sync_if_needed device_id, client_number

		result = {
			processing: false,
			sync_already_running: false,
			sync_already_in_queue: false
		}

		Sidekiq::Workers.new.each do |process_id, thread_id, work|
			payload = work['payload']
			if payload['class'] == 'SyncMediaspotWorker' && payload['args'] == [device_id, client_number]
				result[:sync_already_running] = true
				return result
			end
		end

		Sidekiq::Queue.new.each do |job|
			if job.klass == 'SyncMediaspotWorker' && job.args == [device_id, client_number]
				result[:sync_already_in_queue] = true
				return result
			end
		end


		SyncMediaspotWorker.perform_async(device_id, client_number)

		result[:processing] = true

		result

	end



end