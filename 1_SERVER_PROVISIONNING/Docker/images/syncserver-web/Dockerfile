# README
#
#	before building this image, you need to copy the whole syncserver folder here
#
# using git is a good idea because it won't copy the stuff in .gitignore
# but you have to commit your changes
# rm -rf ./src/
# git clone ../../.. ./src/
#
# !README

FROM        ruby:2.1.5

RUN         apt-get update
RUN         apt-get install -y nodejs
RUN         apt-get install -y cron
RUN         apt-get install -y nginx

COPY        src/ /syncserver/

WORKDIR     /syncserver

COPY        thin.yml /syncserver/config/

RUN         bundle install --without development test --deployment

RUN         bundle exec rake assets:precompile

COPY        start.sh /
COPY        set_mongodb_host.rb /
RUN         chmod 755 /start.sh
RUN         chmod 755 /set_mongodb_host.rb
RUN         chmod 666 /syncserver/config/environments/production.rb

RUN         mkdir /syncserver/tmp/sockets

COPY        syncserver_nginx /etc/nginx/sites-enabled/default

ENTRYPOINT  ["/start.sh"]
# CMD         ["bash"]
# CMD         ["/start.sh"]