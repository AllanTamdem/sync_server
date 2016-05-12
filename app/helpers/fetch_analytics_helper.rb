module FetchAnalyticsHelper



	# Get the names of all the files in the analytics of a client
	def get_unique_files client, mediaspot_id, period

		date_filter = get_date_filter_per_period(period)

	  filter = {client_name: client}
  	filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
		filter[:time.gte] = date_filter

		AnalyticsDownloadsPerHour
		.where(filter)
		.distinct(:file)
		.to_a

	end


	# get all the mediaspots ids that have analytics for a specific client
	def get_unique_mediaspots client, period

		date_filter = get_date_filter_per_period(period)

	  filter = {client_name: client}
		filter[:time.gte] = date_filter

		mediaspots = AnalyticsDownloadsPerHour
		.where(filter)
		.distinct(:mediaspot_id)
		.to_a

	end	

	# Get the names of all the file_types in the analytics of a client
	def get_unique_file_types client, mediaspot_id, period

		date_filter = get_date_filter_per_period(period)

	  filter = {client_name: client}
  	filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
		filter[:time.gte] = date_filter

		AnalyticsDownloadsPerHour
		.where(filter)
		.distinct(:file_type)
		.to_a

	end

	# Get the names of all the device types in the analytics of a client
	def get_unique_device_types client, mediaspot_id, period

		date_filter = get_date_filter_per_period(period)

	  filter = {client_name: client}
  	filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
		filter[:time.gte] = date_filter

		AnalyticsDeviceTypesPerHour
		.where(filter)
		.distinct(:device_type)
		.to_a

	end


	# get the total number of downloads of each file for a specific client
	# optionnaly filter by a specific mediaspot	
	# optionnaly get only the data starting from a specific time
	def get_file_distribution_from_time client, mediaspot_id, time

		map = "
		  function() {

		  	var downloads = 0;
		  	if(this.size > 0){
		  		downloads = this.bytes / this.size;
		  	}

		    emit({file: this.file, size: this.size}, downloads);
		  }"

		reduce = "function(key, values) {
			var downloads = 0;

			values.forEach(function(value) {
				downloads = downloads + value;
			});

	    return downloads;
	  }"


		finalize = "function(key, value) {
	    return {file: key.file, size:key.size, downloads: value};
	  }"


	  filter = {client_name: client}
  	filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
  	filter[:time.gte] = time unless time == nil

	  AnalyticsDownloadsPerHour
	  .where(filter)
  	.map_reduce(map, reduce)
		.out(inline: true)
		.finalize(finalize)
		.to_a.map{|i| i['value']}

	end


	# get the number of downloads per mediaspot for a specific client
	# per hour, day or month
	def get_downloads_per_mediaspot client, period
		date_filter = get_date_filter_per_period(period)
		period_function = get_period_function(period)

		data = get_downloads_per_mediaspot_per_period(client, period_function, date_filter)
		.to_a.map{|i| i['value']}

		data << {time:DateTime.now}
		data.unshift({time:date_filter})

		data

	end


	# get the number of downloads per file for a specific client and mediaspot
	# per hour, day or month
	def get_downloads_per_file client, mediaspot_id, period

		date_filter = get_date_filter_per_period(period)
		period_function = get_period_function(period)

		data = get_downloads_per_file_per_period(client, mediaspot_id, period_function, date_filter)
		.to_a.map{|i| i['value']}

		data << {time:DateTime.now}
		data.unshift({time:date_filter})

		data

	end


	def get_downloads_per_content_type client, mediaspot_id, period
		date_filter = get_date_filter_per_period(period)
		period_function = get_period_function(period)

		data = get_downloads_per_content_type_per_period(client, mediaspot_id, period_function, date_filter)
		.to_a.map{|i| i['value']}

		data << {time:DateTime.now}
		data.unshift({time:date_filter})

		data
	end


	def get_downloads_per_device_type client, mediaspot_id, period
		date_filter = get_date_filter_per_period(period)
		period_function = get_period_function(period)

		data = get_downloads_per_device_type_per_period(client, mediaspot_id, period_function, date_filter)
		.to_a.map{|i| i['value']}

		data << {time:DateTime.now}
		data.unshift({time:date_filter})

		data

	end


	def get_failed_downloads client, mediaspot_id, period
		date_filter = get_date_filter_per_period(period)
		period_function = get_period_function(period)

		data = nil
		if mediaspot_id.blank?
			data = get_failed_downloads_per_period(client, period_function, date_filter)
		else
			data = get_failed_downloads_per_mediaspot_period(client, mediaspot_id, period_function, date_filter)
		end

		data = data.to_a.map{|i| i['value']}

		data << {time:DateTime.now}
		data.unshift({time:date_filter})

		data

	end

	private

		def get_failed_downloads_per_mediaspot_period client, mediaspot_id, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			    emit(time, this.num_failures);
			  }"

			reduce = "
				function(key, values) {

					result_num_failures = 0;

					values.forEach(function(num_failures){
						result_num_failures = result_num_failures + num_failures;
					});

			    return result_num_failures;
			  }"

			finalize = "
				function(key, value) {
			  	var result = {time: key};
			  	result['num_failures_#{mediaspot_id}'] = value;
			    return result;
			  }"

			AnalyticsFailedDownloadsPerHour
			.where(client_name: client,
				mediaspot_id: mediaspot_id,
				:time.gte => date_filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce)
			.out(inline: true)
			.finalize(finalize)

		end

		def get_failed_downloads_per_period client, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			    emit(time, {mediaspots:[{mediaspot_id: this.mediaspot_id, num_failures: this.num_failures}]});
			  }"

			reduce = "
				function(key, values) {
			    var result_mediaspots = [];
			    values.forEach(function(value) {

			    	value.mediaspots.forEach(function(mediaspot){

				    	var found = false;
				    	result_mediaspots.forEach(function(result_mediaspot){
				    		if(result_mediaspot.mediaspot_id == mediaspot.mediaspot_id){
				    			result_mediaspot.downloads = result_mediaspot.num_failures + mediaspot.num_failures;
				    			found = true;
				    		}
			    		});

							if(found == false){
								result_mediaspots.push(mediaspot);
							}

		    		});

			    });
			    return {mediaspots: result_mediaspots};
			  }"

			finalize = "
				function(key, value) {
			  	var result = {time: key};
			  	value.mediaspots.forEach(function(mediaspot){
			  		result['num_failures_' + mediaspot.mediaspot_id] = Math.round(mediaspot.num_failures);
			  	});

			    return result;
			  }"


			AnalyticsFailedDownloadsPerHour
			.where(client_name: client, :time.gte => date_filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce)
			.out(inline: true)
			.finalize(finalize)

		end

		# get the number of downloads per mediaspot for a specific client
		# period_map_function defines the time period (hour, day, month, etc...)
		def get_downloads_per_mediaspot_per_period client, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			  	var downloads = 0;
			  	if(this.size > 0){
			  		downloads = this.bytes / this.size;
			  	}

			    emit(time, {mediaspots:[{mediaspot_id: this.mediaspot_id, downloads: downloads}]});
			  }"

			AnalyticsDownloadsPerHour
			.where(client_name: client, :time.gte => date_filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce_mediaspots_function)
			.out(inline: true)
			.finalize(finalize_mediaspots_function)

		end

		# get the number of downloads per file for a specific client and mediaspot
		# period_map_function defines the time period (hour, day, month, etc...)
		def get_downloads_per_file_per_period client, mediaspot_id, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			  	var downloads = 0;
			  	if(this.size > 0){
			  		downloads = this.bytes / this.size;
			  	}

			    emit(time, {files:[{file_name: this.file, downloads: downloads}]});
			  }"

	  	filter = {client_name: client}	  	
  		filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
  		filter[:time.gte] = date_filter unless date_filter.blank?

			AnalyticsDownloadsPerHour
			.where(filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce_files_function)
			.out(inline: true)
			.finalize(finalize_files_function)

		end

		# get the number of downloads per type of file for a specific client and mediaspot
		# period_map_function defines the time period (hour, day, month, etc...)
		def get_downloads_per_content_type_per_period client, mediaspot_id, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			  	var downloads = 0;
			  	if(this.size > 0){
			  		downloads = this.bytes / this.size;
			  	}

			    emit(time, {types:[{file_type: this.file_type, downloads: downloads}]});
			  }"

			filter = {client_name: client, :file_type.exists => true}			
  		filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
  		filter[:time.gte] = date_filter unless date_filter.blank?

			AnalyticsDownloadsPerHour
			.where(filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce_content_types_function)
			.out(inline: true)
			.finalize(finalize_types_function)

		end

		# get the number of accesses per device type for a specific client and mediaspot
		# period_map_function defines the time period (hour, day, month, etc...)
		def get_downloads_per_device_type_per_period client, mediaspot_id, period_map_function, date_filter

			map = "
			  function() {

			  	var getTime = #{period_map_function}

			  	var time = getTime(this);

			    emit(time, {device_types:[{device_type: this.device_type, accesses: this.accesses}]});
			  }"

			filter = {client_name: client}
  		filter[:mediaspot_id] = mediaspot_id unless mediaspot_id.blank?
  		filter[:time.gte] = date_filter unless date_filter.blank?

			AnalyticsDeviceTypesPerHour
			.where(filter)
			.order_by(:time.asc)
			.map_reduce(map, reduce_device_types_function)
			.out(inline: true)
			.finalize(finalize_device_types_function)

		end



		def get_period_function period
			period_function = per_day_function
			period_function = per_hour_function if period == 'hour'
			period_function = per_month_function if period == 'month'

			period_function
		end


		def get_date_filter_per_period period
			date_filter = DateTime.now - 6.months
			date_filter = DateTime.now - 1.month if period == 'hour'
			date_filter = DateTime.now - 1.year if period == 'month'

			date_filter
		end



		#
		# functions mapping an hour of time to a period of time (hour, day, month)
		#
		def per_hour_function

			"function(entry){
					return new Date(entry.time);
		  	}
			"
		end

		# get the day of a time
		def per_day_function

			"function(entry){
			  	var date = new Date(entry.time);
	  			return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
		  	}
			"
		end

		# get the month of a time
		def per_month_function

			"function(entry){
			  	var date = new Date(entry.time);
	  			return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth()));
		  	}
			"
		end




		#
		# REDUCE FUNCTIONS
		#

		# reduce function for the mediaspots functions
		def reduce_mediaspots_function
			"function(key, values) {
		    var result_mediaspots = [];
		    values.forEach(function(value) {

		    	value.mediaspots.forEach(function(mediaspot){

			    	var found = false;
			    	result_mediaspots.forEach(function(result_mediaspot){
			    		if(result_mediaspot.mediaspot_id == mediaspot.mediaspot_id){
			    			result_mediaspot.downloads = result_mediaspot.downloads + mediaspot.downloads;
			    			found = true;
			    		}
		    		});

						if(found == false){
							result_mediaspots.push(mediaspot);
						}

	    		});

		    });
		    return {mediaspots: result_mediaspots};
		  }"
		end

		# reduce function for the files functions
		def reduce_files_function
			"function(key, values) {
			    var result_files = [];

			    values.forEach(function(value) {

		    		value.files.forEach(function(file){

					    	var found = false;
					    	result_files.forEach(function(result_file){
					    		if(result_file.file_name == file.file_name){
					    			result_file.downloads = result_file.downloads + file.downloads;
					    			found = true;
					    		}
				    		});

								if(found == false){
									result_files.push(file);
								}
	    			});

			    });
			    return {files: result_files};
			  }"
		end


		# emit(time, {types:[{file_type: this.file_type, downloads: downloads}]});
		# reduce function for the file_types functions
		def reduce_content_types_function
			"function(key, values) {
			    var result_types = [];

			    values.forEach(function(value) {

		    		value.types.forEach(function(type){

					    	var found = false;
					    	result_types.forEach(function(result_type){
					    		if(result_type.file_type == type.file_type){
					    			result_type.downloads = result_type.downloads + type.downloads;
					    			found = true;
					    		}
				    		});

								if(found == false){
									result_types.push(type);
								}
	    			});

			    });
			    return {types: result_types};
			  }"
		end


		# emit(time, {device_types:[{device_type: this.device_type, accesses: accesses}]});
		# reduce function for the device_types functions
		def reduce_device_types_function
			"function(key, values) {
			    var result_device_types = [];

			    values.forEach(function(value) {

		    		value.device_types.forEach(function(device_type){

					    	var found = false;
					    	result_device_types.forEach(function(result_device_type){
					    		if(result_device_type.device_type == device_type.device_type){
					    			result_device_type.accesses = result_device_type.accesses + device_type.accesses;
					    			found = true;
					    		}
				    		});

								if(found == false){
									result_device_types.push(device_type);
								}
	    			});

			    });
			    return {device_types: result_device_types};
			  }"
		end



		#
		# FINALIZE FUNCTIONS
		#

		# finalize function for the mediaspots functions
		def finalize_mediaspots_function
			"function(key, value) {
		  	var result = {time: key};
		  	value.mediaspots.forEach(function(mediaspot){
		  		result['downloads_' + mediaspot.mediaspot_id] = Math.round(mediaspot.downloads);
		  	});

		    return result;
		  }"
		end

		# finalize function for the files functions
		def finalize_files_function
			"function(key, value) {
		  	var result = {time: key};
		  	value.files.forEach(function(file){
		  		result['downloads_' + file.file_name] = Math.round(file.downloads);
		  	});

		    return result;
		  }"
		end

		# finalize function for the file_type functions
		def finalize_types_function
			"function(key, value) {
		  	var result = {time: key};
		  	value.types.forEach(function(type){
		  		result['downloads_' + type.file_type] = Math.round(type.downloads);
		  	});

		    return result;
		  }"
		end

		# finalize function for the file_type functions
		def finalize_device_types_function
			"function(key, value) {
		  	var result = {time: key};
		  	value.device_types.forEach(function(device_type){
		  		result['downloads_' + device_type.device_type] = device_type.accesses;
		  	});

		    return result;
		  }"
		end

end
