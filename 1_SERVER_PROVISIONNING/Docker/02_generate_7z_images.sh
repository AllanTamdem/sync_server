# prerequisite :
# sudo apt-get install -y p7zip-full

docker save -o fcd_redis.tar fcd/redis
echo "fcd_redis.tar ready"
docker save -o fcd_mongodb.tar fcd/mongodb
echo "fcd_mongodb.tar ready"
docker save -o fcd_genieacs.tar fcd/genieacs
echo "fcd_genieacs.tar ready"
docker save -o fcd_genieacs-gui.tar fcd/genieacs-gui
echo "fcd_genieacs-gui.tar ready"

docker save -o fcd_postgres.tar fcd/postgres
echo "fcd_postgres.tar ready"
docker save -o fcd_labgency-sdk-php.tar fcd/labgency-sdk-php
echo "fcd_labgency-sdk-php.tar ready"
docker save -o fcd_websocket-node.tar fcd/websocket-node
echo "fcd_websocket-node.tar ready"
docker save -o fcd_syncserver-web.tar fcd/syncserver-web
echo "fcd_syncserver-web.tar ready"

7z a tr069_images.7z fcd_redis.tar fcd_mongodb.tar fcd_genieacs.tar fcd_genieacs-gui.tar
echo "tr069_images.7z ready"
7z a syncserver_images.7z fcd_redis.tar fcd_postgres.tar fcd_labgency-sdk-php.tar fcd_websocket-node.tar fcd_syncserver-web.tar 
echo "syncserver_images.7z ready"

echo "removing tar files"
rm fcd_redis.tar
rm fcd_mongodb.tar
rm fcd_genieacs.tar
rm fcd_genieacs-gui.tar

rm fcd_postgres.tar
rm fcd_labgency-sdk-php.tar
rm fcd_websocket-node.tar
rm fcd_syncserver-web.tar
echo "end of script"