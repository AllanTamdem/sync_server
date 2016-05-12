include ContentProvidersHelper
include Tr069Helper
include PathHelper

#
# Capturing events on the S3 buckets
# So we can trigger a synchronization on the mediaspot to update its content
#


if Rails.env.production? && !Rails.const_defined?('Console')   # otherwise, each cron task will run this as well
# if !Rails.const_defined?('Console')   # otherwise, each cron task will run this as well

	sqs_client = Aws::SQS::Client.new(
	  region: Rails.configuration.aws_region,
	  access_key_id: Rails.configuration.aws_access_key_id,
	  secret_access_key: Rails.configuration.aws_secret_access_key
	)

	queue_url = sqs_client.get_queue_url(queue_name: Rails.configuration.aws_sqs_s3_events).queue_url

	sqs_poller = Aws::SQS::QueuePoller.new(queue_url, client: sqs_client)

	Thread.new do

		# options = {}
		# options[:skip_delete] = false

		# # if not in production, we don't delete the message
		# if Rails.env.production? == false
		# 	options[:skip_delete] = true
		# end

		# sqs_poller.poll(options) do |msg|
		sqs_poller.poll do |msg|

			log_msg = "SQS message received: message #{msg.body}"
			Rails.logger.info(log_msg)
			p log_msg

			ProcessS3EventWorker.perform_async(msg.body)
		end

	end

end







