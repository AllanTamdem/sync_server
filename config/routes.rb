Rails.application.routes.draw do

  require 'sidekiq/web'
  
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'repo2#index'
  # root 'repo#index'
  # get 'v2/' => "repo2#index"

  get 'logs/' => "logs#index"
  get 'logs/sidekiq/' => "logs#sidekiq"
  get 'logs/cron/' => "logs#cron"
  get 'logs/node_ws/' => "logs#node_ws"
  post 'logs/create_rails_log/' => "logs#create_rails_log"

  get 'sandbox' => 'sandbox#index'
  get 'sandbox/test' => 'sandbox#test'
  get 'sandbox/test2' => 'sandbox#test2'
  get 'sandbox/test3' => 'sandbox#test3'
  get 'sandbox/sidekiq_jobs' => 'sandbox#sidekiq_jobs'

  get 's3/get_files' => 's3#get_files'
  # get 's3/get_file_size' => 's3#get_file_size'
  # get 's3/get_files_with_last_modified_date' => 's3#get_files_with_last_modified_date'
  post 's3/upload' => 's3#upload'
  delete 's3/delete' => 's3#delete'
  get 's3/get_form' => 's3#get_form'
  post 's3/modify_file' => 's3#modify_file'
  get 's3/get_jobs' => 's3#get_jobs'
  # post 's3/set_metadata' => 's3#set_metadata'
  post 's3/sign_auth' => 's3#sign_auth'

  get 's3/get_files_as_tree' => 's3v2#get_files_as_tree'
  get 's3/sign_auth_upload' => 's3v2#sign_auth_upload'
  post 's3/create_folder' => 's3v2#create_folder'
  post 's3/delete_files' => 's3v2#delete_files'
  post 's3/cut_paste_files' => 's3v2#cut_paste_files'
  post 's3/copy_paste_files' => 's3v2#copy_paste_files'
  post 's3/rename_file' => 's3v2#rename_file'
  get 's3/fetch_metadata' => 's3v2#fetch_metadata'
  post 's3/validate_metadata' => 's3v2#validate_metadata'
  post 's3/set_metadata' => 's3v2#set_metadata'
  get 's3/file_download_url' => 's3v2#file_download_url'
  get 's3/get_files_with_last_modified_date' => 's3v2#get_files_with_last_modified_date'
  get 's3/get_file_size' => 's3v2#get_file_size'
  post 's3/upload_complete' => 's3v2#upload_complete'

  get 'helpers/generate_api_key' => 'helpers#generate_api_key'

  get 'profile' => 'profile#index'
  post 'profile' => 'profile#index'

  get 'api' => 'apidoc#index'

  get 'analytics/files_distribution' => 'analytics#files_distribution'
  get 'analytics/downloads' => 'analytics#downloads'

  get 'api/files' => 'api#files'
  delete 'api/files' => 'api#delete' #must be with a key parameter ( like /api/files?key=star_wars_7 )
  get 'api/presigned_post' => 'api#presigned_post'

  get 'repository_log' => 'repositorylog#index'
  get 'repository_log/:id' => 'repositorylog#get'

  get 'admin_mediaspots' => 'admin_mediaspots#index'
  get 'admin_mediaspots/get_mediaspots' => 'admin_mediaspots#get_mediaspots'
  get 'admin_mediaspots/add_client' => 'admin_mediaspots#add_client'
  get 'admin_mediaspots/remove_client' => 'admin_mediaspots#remove_client'
  get 'admin_mediaspots/set_client_parameter' => 'admin_mediaspots#set_client_parameter'
  get 'admin_mediaspots/get_task_queue' => 'admin_mediaspots#get_task_queue'
  get 'admin_mediaspots/get_all_tasks' => 'admin_mediaspots#get_all_tasks'
  get 'admin_mediaspots/refresh_all' => 'admin_mediaspots#refresh_all'
  get 'admin_mediaspots/get_sync_status' => 'admin_mediaspots#get_sync_status'
  get 'admin_mediaspots/delete_mediaspot' => 'admin_mediaspots#delete_mediaspot'
  get 'admin_mediaspots/delete_mediaspot_tasks' => 'admin_mediaspots#delete_mediaspot_tasks'
  get 'admin_mediaspots/reboot_mediaspot' => 'admin_mediaspots#reboot_mediaspot'
  get 'admin_mediaspots/set_mediaspot_wifi_setting' => 'admin_mediaspots#set_mediaspot_wifi_setting'
  post 'admin_mediaspots/set_mediaspot_internet_white_list' => 'admin_mediaspots#set_mediaspot_internet_white_list'
  post 'admin_mediaspots/set_mediaspot_custom_info' => 'admin_mediaspots#set_mediaspot_custom_info'
  post 'admin_mediaspots/set_mediaspot_internet_blocking_enabled' => 'admin_mediaspots#set_mediaspot_internet_blocking_enabled'
  post 'admin_mediaspots/set_mediaspot_parameter' => 'admin_mediaspots#set_mediaspot_parameter'



  get 'site_settings' => 'site_settings#index'
  patch 'site_settings/update_metadata_template' => 'site_settings#update_metadata_template'
  patch 'site_settings/update_metadata_validation_schema' => 'site_settings#update_metadata_validation_schema'
  patch 'site_settings/update_tr69_hosts_whitelist' => 'site_settings#update_tr69_hosts_whitelist'
  patch 'site_settings/update_websocket_hosts_whitelist' => 'site_settings#update_websocket_hosts_whitelist'
  patch 'site_settings/update_super_admins' => 'site_settings#update_super_admins'

  get 'mediaspots' => 'mediaspots#index'
  get 'mediaspots2' => 'mediaspots#index'
  get 'mediaspots/get_mediaspots' => 'mediaspots#get_mediaspots'
  get 'mediaspots/set_client_parameter' => 'mediaspots#set_client_parameter'
  post 'mediaspots/get_task_queue' => 'mediaspots#get_task_queue'


  get 'labgency' => 'labgency#index'
  get 'labgency/catalog' => 'labgency#catalog'
  get 'labgency/logs' => 'labgency#logs'
  post 'labgency/run_batch' => 'labgency#run_batch'

  get 'alerts/' => "alerts#index"
  get 'sms_status/' => "sms_status#index"

  get 'application_logs' => 'application_logs#index'

  get '/favicon.ico', to: redirect('/images/favicon.ico')

  post 'sms_status/update' => "sms_status#update"
  
  devise_for :users, controllers: { sessions: "users/sessions", passwords: "passwords/passwords" }

  resources :users
  resources :content_providers

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
