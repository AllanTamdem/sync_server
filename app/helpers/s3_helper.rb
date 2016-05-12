module S3Helper


	include PathHelper
		

	def s3_get_file_download_url s3_info, key
		s3_bucket(s3_info).objects[key].url_for(:get)
	end

	def s3_get_file_size s3_info, key
		bucket = s3_bucket(s3_info)
		if bucket.objects[key].exists?
			return bucket.objects[key].content_length
		else
			return nil
		end		
	end


	def s3_get_files s3_info, path

		path = path_prettify path

		begin

			s3_client = get_s3_client(s3_info)

			resp = s3_client.list_objects(bucket: s3_info[:aws_bucket_name], prefix: path)

			# files = s3_bucket(s3_info).objects.with_prefix(path)
			files = resp.contents
			.map { |o|									
				{
					key: o.key,
					file: o.key[path.length..-1],			
					head: {content_length: nil, last_modified: nil},
					url_for_read: nil
				}
			}
			.select{|o|
				false == (o[:key].end_with?('/')) # this is an empty folder
			}

			return {error: nil, files: files}

		rescue Aws::S3::Errors::ServiceError => ex
			return {error: "#{ex.class}: #{ex.message}", files: []}
		end
	end


	def s3_get_files_detailed s3_info, path

		path = path_prettify path

		begin		
		
			files = s3_bucket(s3_info).objects.with_prefix(path)
			.select { |o|
				o.head and (false == (o.key.end_with?('/') and o.head.content_length == 0)) # this is an empty folder				
			}
			.map { |o|
				{
					key: o.key,
					file: o.key[path.length..-1],			
					head: o.head.to_h,
					url_for_read: o.url_for(:get).to_s,
					size_pretty: Filesize.from(o.head[:content_length].to_s + " B").pretty
				}
			}

			return {error: nil, files: files}

		rescue AWS::Errors::ClientError => ex
			return {error: "#{ex.class}: #{ex.message}", files: []}
		end

	end


	def s3_get_files_with_last_modified_date s3_info, path

		path = path_prettify path
		
		s3_bucket(s3_info).objects.with_prefix(path)
		.map { |o|
			{
				key: o.key,
				head: {last_modified:o.head[:last_modified]}
			}
		}

	end

	def s3_create_file s3_info, key, data
		s3_bucket(s3_info).objects[key].write(data)
	end

	def s3_delete_file s3_info, key
		bucket = s3_bucket(s3_info)
		bucket.objects[key].delete()

		# we need to delete the metadata as well
		if(!key.end_with?('.json') and bucket.objects[key + '.json'].exists?)
			bucket.objects[key + '.json'].delete()
		end
	end

	def s3_exists? s3_info, key
		 s3_bucket(s3_info).objects[key].exists?
	end

	def s3_get_form s3_info,path, metaFields

		key = path_prettify(path) + "${filename}"

		form = s3_bucket(s3_info).presigned_post(key:  key, secure: true)

		metaFields.each { |metaField|
			form = form.where_metadata(metaField).starts_with("")
		}

		{ url: form.url.to_s, fields: form.fields }
	end


	def s3_modify_file s3_info, key, new_path, metadata

		bucket = s3_bucket(s3_info)

		bucket.objects[key].copy_to(new_path, {metadata: metadata})

		if(key != new_path)
			bucket.objects[key].delete()
		end

		# we need to move the metadata as well
		if(!key.end_with?('.json') and bucket.objects[key + '.json'].exists?)

			bucket.objects[key + '.json'].copy_to(new_path + '.json')

			SaveFileTypeForAnalyticsWorker.perform_async(s3_info, new_path, nil)

			if(key != new_path)
				bucket.objects[key + '.json'].delete()
			end
		end
	end


	def s3_modify_file_simple s3_info, key, new_path, metadata

		bucket = s3_bucket(s3_info)

		bucket.objects[key].copy_to(new_path, {metadata: metadata})

		if(key != new_path)
			bucket.objects[key].delete()
		end
	end

	def s3_hostname_by_region region

		if region == 'us-east-1'
			return 's3.amazonaws.com'
		else
			return "s3-#{region}.amazonaws.com"
		end		

	end

	private 

		def get_s3_client s3_info

			Aws::S3::Client.new(
			  access_key_id: s3_info[:aws_bucket_access_key_id],
			  secret_access_key: s3_info[:aws_bucket_secret_access_key],
			  region: s3_info[:aws_bucket_region])

		end

		def s3_bucket s3_info

			bucket = AWS::S3.new(
			  access_key_id: s3_info[:aws_bucket_access_key_id],
			  secret_access_key: s3_info[:aws_bucket_secret_access_key],
			  region: s3_info[:aws_bucket_region])
			.buckets[s3_info[:aws_bucket_name]]

			bucket
		end

end