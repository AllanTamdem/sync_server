How to run an Ansible playbook:
$ ansible-playbook -i hosts playbook.yml


Provisioning the TR069 and SyncServer(prod and staging) servers.
----------------------------------------------------------------

1. to install basic stuff on all the servers, run the basic.yml playbook

2. to install and setup the TR069 server, run the tr069.yml playbook

3. to install and setup the SyncServer:

	A. run the sync-server-pre-deploy.yml playbook

	B. install the sync-server code by using capistrano from the rails app

	C. run the sync-server.yml playbook



Other optionnal playbooks (the order is not important)
------------------------------------------------------

. aws-cloudwatch.yml
	Setups the monitoring of all servers with AWS CloudWatch.
	It is monitoring RAM, SWAP and disk space

. mongodb-daily-backup-s3.yml
	Setups a daily backup of the mongoDB to s3

. postgres-daily-backup-s3.yml
	Setups a daily backup of the PostgreSQL DB to s3

