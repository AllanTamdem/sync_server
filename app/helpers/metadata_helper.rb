module MetadataHelper

  	require 'json'

	def metadata_validate metadata
		errors = []

		parsed = nil

		begin
			parsed = JSON.parse(metadata)
		rescue
			errors << 'invalid JSON'
			return errors
		end

		errors.concat check_mandatory_key(parsed,
			["id",
      "type",
      "typeLabel",
      "title",
      "description",
      "imageUrl",
      "size",
      "releaseDate",
      "validationPlatform",
      "validationPlatformData",
      "isPromo",
      "mimeType",
      "adImageUrl",
      "adWebSiteUrl",
      "contentSponsor"],
			'The "[[KEY]]" value is mandatory')

		if parsed.key?('validationPlatform') and parsed['validationPlatform'] != nil

			# if ['orange', 'labgency'].include?(parsed['validationPlatform'])
			if parsed['validationPlatform'] == 'orange'
				if (parsed['validationPlatformData'] || {}).key?('mediaUrl') == false or
					parsed['validationPlatformData']['mediaUrl'] == nil
					errors << 'For the "orange" validationPlatform, the "validationPlatformData.mediaUrl" is mandatory'
				end
				if (parsed['validationPlatformData'] || {}).keys.count > 1
					errors << 'For the "orange" validationPlatform, validationPlatformData must only contains "mediaUrl"'
				end
			elsif parsed['validationPlatform'] == 'labgency'
				if (parsed['validationPlatformData'] || {}).key?('cid') == false or
					parsed['validationPlatformData']['cid'] == nil
					errors << 'For the "labgency" validationPlatform, the "validationPlatformData.cid" is mandatory'
				end
				if (parsed['validationPlatformData'] || {}).keys.count > 1
					errors << 'For the "labgency" validationPlatform, validationPlatformData must only contains "cid"'
				end
			else
				errors << '"validationPlatform" must be either "orange" or "labgency"'
			end
		end


		if parsed.key?('type') and parsed['type'] != nil

			if parsed['type'] == "movie"
				errors.concat check_mandatory_key(parsed,
					[ "genre", "director", "actors", "country", "duration", "rating", "ageRating"],
					'For a content of type "movie", The "[[KEY]]" value is mandatory')

			elsif parsed['type'] == "serie"
				errors.concat check_mandatory_key(parsed,
					[ "episodeTitle", "seasonNumber", "episodeNumber", "director", "actors", "country", "duration", "rating", "ageRating"],
					'For a content of type "series", The "[[KEY]]" value is mandatory')

			elsif parsed['type'] == "book"
				errors.concat check_mandatory_key(parsed,
					[ "author", "editor"],
					'For a content of type "book", The "[[KEY]]" value is mandatory')

			elsif parsed['type'] == "newspaper"
				errors.concat check_mandatory_key(parsed,
					[ "number", "editor"],
					'For a content of type "newspaper", The "[[KEY]]" value is mandatory')

			elsif parsed['type'] == "music"
				errors.concat check_mandatory_key(parsed,
					[ "duration", "trackTitle", "author", "editor" ],
					'For a content of type "music", The "[[KEY]]" value is mandatory')

			else
				errors << '"type" must be either "movie", "series", "book", "newspaper" or "music"'
			end

		end

		# check if it's integer

		['inCatalogueFrom', 'inCatalogueUntil', 'duration', 'rating'].each do |k|
			if parsed.key?(k) and parsed[k] != nil
				if false == is_integer?(parsed[k])
					errors << '"' + k + '" must be an integer'
				end
			end
		end

		errors
	end

	private

		def check_mandatory_key obj, keys, msg
			errors = []
			keys.each do |k|
				if !obj.key?(k) or obj[k] == nil
					msg2 = msg.sub('[[KEY]]', k)
					if k == 'duration' or k == 'rating'
						msg2 += ' and must be a number'
					end
					if k == 'isPromo'
						msg2 += ' and must be true or false'
					end
					errors << msg2
				end			
			end
			errors
		end

		def is_integer? val
			begin
				Integer(val)
				return true
			rescue
				return false
			end
		end

end