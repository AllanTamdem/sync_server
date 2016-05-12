

building images locally:

TR69 :
$ docker build -t fcd/redis ./redis/
$ docker build -t fcd/mongodb ./mongodb/
$ docker build -t fcd/genieacs ./genieacs/
$ docker build -t fcd/genieacs-gui ./genieacs-gui/

syncserver :
$ docker build -t fcd/redis ./redis/  # you can reuse the one from tr069
$ docker build -t fcd/postgres ./postgres/
$ docker build -t fcd/labgency-sdk-php ./labgency-sdk-php/
$ docker build -t fcd/websocket-node ./websocket-node/
$ docker build -t fcd/syncserver-web ./syncserver-web/


 
Starting the containers on the TR69 server : 
$ docker run --name redis -p 6379:6379 -v /var/log/docker_redis:/var/log/redis -d fcd/redis
$ docker run --name mongodb -p 27017:27017 -v /var/log/docker_mongodb:/var/log/mongodb -d fcd/mongodb
$ docker run --name genieacs --net="host" -v /var/log/docker_genieacs:/var/log/supervisor -d fcd/genieacs
$ docker run --name genieacs-gui --net="host" -v /var/log/docker_genieacs-gui:/geniacs-gui/log -d fcd/genieacs-gui
 

Starting the containers on the syncserver server : 
$ docker run --name redis -p 6379:6379 -v /var/log/docker_redis:/var/log/redis -d fcd/redis
$ docker run --name postgres -p 5432:5432 -v /var/log/docker_postgresql:/var/log/postgresql -e "DB=production" -e "USER=rails-mediaspot-sync" -e "PW=dx9zrBnq" -d fcd/postgres
$ docker run --name labgency-sdk-php -p 3549:80 -d fcd/labgency-sdk-php
$ docker run --name websocket-node -p 3051:3051 -p 3052:3052 -d fcd/websocket-node
# production :
$ docker run --name syncserver-web --net="host" -e "environment=production" -e "logentries=20c59777-0bbe-4fa3-99f7-41109405b7fc" -e "domain=syncserver.tapngo.orangejapan.jp" -e "tr069=52.68.160.44" -v /var/log/docker_syncserver-web:/syncserver/log -d fcd/syncserver-web
# staging :
$ docker run --name syncserver-web --net="host" -e "environment=staging" -e "logentries=efddb053-c24b-432c-af17-c0bacc787a1f" -e "domain=syncserverstaging2.tapngo.orangejapan.jp" -d fcd/syncserver-web



docker run --name syncserver-web --net="host" -e "environment=production" -e "logentries=efddb053-c24b-432c-af17-c0bacc787a1f" -e "domain=syncserver.tapngo.orangejapan.jp" -e "tr069=52.16.103.212" -e "ws_api=http://52.17.226.202:3052" -d fcd/syncserver-web

Host docker
  HostName 52.68.160.44
  User ubuntu  

Host docker-syncserver
  HostName 52.69.91.111
  User ubuntu


- redis
- postgres
- syncserver-websocket-node
- labgency-sdk-php
- syncserver-web-rails



how to ship an image on the server (example redis):

1. locally, save the container as a tar file
$ docker save -o fcd_redis.tar fcd/redis

2. send the container to the server
$ scp fcd_redis.tar host:~

3. on the server, load the image
$ docker load -i fcd_redis.tar

4. start the container
$ docker run --name redis -p 6379:6379 -d fcd/redisd