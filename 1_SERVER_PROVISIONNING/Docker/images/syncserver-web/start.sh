#!/bin/sh

echo "******** $environment *******"


if [ -n "$domain" ]; then
	echo "******setting config.domain $domain on $environment.rb******"
	sed -i "s~config.domain = *~config.domain = '$domain' # ~" /syncserver/config/environments/$environment.rb
fi

if [ -n "$logentries" ]; then
	echo "******setting config.logentries_token $logentries on $environment.rb******"
	sed -i "s~config.logentries_token = *~config.logentries_token = '$logentries' # ~" /syncserver/config/environments/$environment.rb
fi

if [ -n "$tr069" ]; then
	echo "******setting config.tr069_api_host $tr069 on $environment.rb******"
	sed -i "s~config.tr069_api_host = *~config.tr069_api_host = '$tr069' # ~" /syncserver/config/environments/$environment.rb

	echo "******setting config.tr069_pubsub_host $tr069 on $environment.rb******"
	sed -i "s~config.tr069_pubsub_host = *~config.tr069_pubsub_host = '$tr069' # ~" /syncserver/config/environments/$environment.rb
fi

if [ -n "$ws_api" ]; then
	echo "******setting config.node_ws_api $ws_api on $environment.rb******"
	sed -i "s~config.node_ws_api = *~config.node_ws_api = '$ws_api' # ~" /syncserver/config/environments/$environment.rb
fi

if [ -n "$mongodb" ]; then
	echo "******setting mongodb host on $mongodb on mongoid.yml******"
	ruby /set_mongodb_host.rb "$environment" "$mongodb"
fi

echo "******db:migrate******"
RAILS_ENV="$environment" bundle exec rake db:migrate

echo "******update-crontab******"
bundle exec whenever --update-crontab sync-server --set environment=$environment --roles=web,app,db

echo "******start thin******"
RAILS_ENV="$environment" bundle exec thin start -C /syncserver/config/thin.yml

echo "******start nginx******"
service nginx start

echo "******start sidekiq******"
bundle exec sidekiq --index 0 --pidfile /syncserver/tmp/pids/sidekiq.pid --environment $environment --logfile /syncserver/log/sidekiq.log

