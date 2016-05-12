class Log < ActiveRecord::Base
	

	def self.search(search)
	  if search.blank?
	    all
	  else

	  	#construct search query

	  	queries = []	  	
	  	Log.columns_hash.each { |key, value|
	  		if [:text, :string].include? value.type
	  			if key == 'user'
	  				key = '"user"'
	  			end
	  			queries << " lower(" + key + ") LIKE '%#{search.downcase}%'"
	  			# queries << " " + key + " LIKE '%#{search}%'"
	  		end
	  	}

	  	query = queries.join(' or ')
	  	# query = " lower(\"user\") LIKE '%#{search.downcase}%'"

	  	p query
	  	where(query)
	  end
	end


end
