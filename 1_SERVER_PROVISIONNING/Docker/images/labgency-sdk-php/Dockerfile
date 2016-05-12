# README
#
#	before building this image, you need to copy the data from LabgencyPhpSdk to ./data
#
# cp ../../../LabgencyPhpSdk/* src/
#
# !README

FROM        php:5.6-apache

RUN         apt-get update

RUN         apt-get install -y php5-fpm php5-curl php5-mcrypt libmcrypt-dev

RUN         docker-php-ext-install mcrypt

COPY        src/ /var/www/html/
