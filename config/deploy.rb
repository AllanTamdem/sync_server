lock '3.4.0'

set :application, 'sync-server'

# capistrano will deploy the code from this repo to the target machine
set :repo_url, 'git@bitbucket.org:julien-orange/sync_server.git'

# capistrano will deploy the code this folder
set :deploy_to, '/home/ubuntu/sync-server'


set :log_level, :info
set :linked_files, fetch(:linked_files, []).push('config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')


namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute '/etc/init.d/syncserver restart'
    end
  end

	after :publishing, :restart


  desc 'Runs rake db:seed'
	task :seed => [:set_rails_env] do
	  on primary fetch(:migration_role) do
	    within release_path do
	      with rails_env: fetch(:rails_env) do
	        execute :rake, "db:seed"
	      end
	    end
	  end
	end

end
