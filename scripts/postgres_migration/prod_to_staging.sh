#!/bin/bash

filename="postgres_dump_$(date +%s).bak"
source="ubuntu@52.17.226.202"
destination="ubuntu@52.17.123.189"


echo "-----------------------------------"
echo "-1/6------creating dump file $filename"
echo "ssh $source 'sudo -u postgres pg_dump -Fc production > $filename'"
ssh "$source" "sudo -u postgres pg_dump -Fc production > $filename"
echo "-----------------------------------"

echo "-2/6------fetching dump file from source server"
echo "scp $source:~/$filename ."
scp "$source":~/"$filename" .
echo "-----------------------------------"

echo "-3/6------deleting remote dump file on source"
echo "ssh $source 'rm $filename'"
ssh "$source" "rm $filename"
echo "-----------------------------------"

echo "-4/6------copying dump file to destination"
echo "scp $filename $destination:~/"
scp "$filename" "$destination":~/
echo "-----------------------------------"

echo "-5/6------restoring dump file on destination db"
echo "ssh $destination 'sudo -u postgres pg_restore --clean -d staging -Fc $filename'"
ssh "$destination" "sudo -u postgres pg_restore --clean -d staging -Fc $filename"
echo "-----------------------------------"
# if the db is in a docker container, we need to use this command :
# docker run --rm -i --link postgres:postgres -v $PWD/:/tmp/ fcd/postgres bash -c 'exec pg_restore --clean -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -d staging /tmp/postgres_dump_1434533438.bak'


echo "-6/6------deleting remote dump file on destination"
echo "ssh $destination 'rm $filename'"
ssh "$destination" "rm $filename"
echo "-----------------------------------"

