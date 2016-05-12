#to run on the tr069 server after having sent the tr069_images.7z file
7z x tr069_images.7z
docker load -i fcd_redis.tar
docker load -i fcd_mongodb.tar
docker load -i fcd_genieacs.tar
docker load -i fcd_genieacs-gui.tar

rm fcd_redis.tar
rm fcd_mongodb.tar
rm fcd_genieacs.tar
rm fcd_genieacs-gui.tar