#!/bin/bash

filename="postgres_dump_$(date +%s).bak"
source="ubuntu@52.17.226.202"
destination="ubuntu@52.17.123.189"


echo "-----------------------------------"
echo "-1/5------creating production dump file $filename"
echo "ssh $source 'sudo -u postgres pg_dump -Fc production > $filename'"
ssh "$source" "sudo -u postgres pg_dump -Fc production > $filename"
echo "-----------------------------------"

echo "-2/5------fetching dump file from production server"
echo "scp $source:~/$filename ."
scp "$source":~/"$filename" .
echo "-----------------------------------"

echo "-3/5------deleting remote dump file on production server"
echo "ssh $source 'rm $filename'"
ssh "$source" "rm $filename"
echo "-----------------------------------"

echo "-4/5------restoring dump file on development db"
echo "sudo -u postgres pg_restore --clean -d development -Fc $filename"
sudo -u postgres pg_restore --clean -d development -Fc "$filename"
echo "-----------------------------------"

echo "-5/5------deleting dump file on local"
echo "rm $filename"
rm "$filename"
echo "-----------------------------------"

