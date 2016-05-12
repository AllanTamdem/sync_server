# class S3ModifyFileWorker
#   include Sidekiq::Worker

#   sidekiq_options retry: false
  
#   include S3Helper

#   def perform(custom_param, s3_info, old_key, new_path_with_key, metadata)

# 		s3_modify_file(s3_info.symbolize_keys, old_key, new_path_with_key, metadata)
		
#   end

# end