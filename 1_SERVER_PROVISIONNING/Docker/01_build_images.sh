
docker build -t fcd/redis ./images/redis/ #for tr069 and syncserver
docker build -t fcd/mongodb ./images/mongodb/ #for tr069
docker build -t fcd/genieacs ./images/genieacs/ #for tr069
docker build -t fcd/genieacs-gui ./images/genieacs-gui/ #for tr069
docker build -t fcd/postgres ./images/postgres/ #for syncserver
docker build -t fcd/labgency-sdk-php ./images/labgency-sdk-php/ #for syncserver
docker build -t fcd/websocket-node ./images/websocket-node/ #for syncserver
docker build -t fcd/syncserver-web ./images/syncserver-web/ #for syncserver