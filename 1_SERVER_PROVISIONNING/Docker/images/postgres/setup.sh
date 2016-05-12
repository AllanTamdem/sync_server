#!/bin/bash
echo "******CREATING DOCKER DATABASE******"
gosu postgres postgres --single <<- EOSQL
   CREATE DATABASE "$DB";
   CREATE USER "$USER" WITH PASSWORD '$PW';
   GRANT ALL PRIVILEGES ON DATABASE "$DB" to "$USER";
EOSQL
echo ""
echo "******DOCKER DATABASE CREATED******"



   # CREATE DATABASE "production";
   # CREATE USER "rails-mediaspot-sync" WITH PASSWORD 'dx9zrBnq';
   # GRANT ALL PRIVILEGES ON DATABASE "production" to "rails-mediaspot-sync";