

BuspassDeployer::Application.routes.draw do
  resources :installations  do
    member do
      get :edit_frontend_git
      get :edit_server_endpoint_git
      get :edit_worker_endpoint_git

      put :update_frontend_git
      put :update_server_endpoint_git
      put :update_worker_endpoint_git

      post :create_all
      post :deploy_all
      post :start_all
      post :restart_all
      post :stop_all
      post :destroy_all

      post :clear_log
      get  :partial_status
      post :ping_remote_status

      get  :job_status
      get  :deploy_status
      get  :partial_deploy_status
      post :destroy_all_jobs
    end
  end

  resources :frontends do
    member do
      post   :create_remote
      post   :configure_remote
      post   :deconfigure_remote
      post   :start_remote
      post   :stop_remote
      post   :deploy_to_remote
      post   :restart_remote
      post   :destroy_remote
      post   :clear_log
      post   :restart_all_endpoint_apps
      get    :partial_status
      delete :delete
    end
    resources :backends, :controller => "frontends/backends" do
      collection do
        post :start_all
        post :restart_all
        post :stop_all
        post :status_all
        get  :status_all
        get  :edit_software
        post :update_software

        get :partial_status
        post :clear_log
      end
      member do
        post :configure
        post :start
        post :restart
        post :stop
        post :status
        get :status
        post :deconfigure

        post :create_all_server_endpoint_apps
        post :configure_all_server_endpoint_apps
        post :start_all_server_endpoint_apps
        post :restart_all_server_endpoint_apps
        post :deploy_all_server_endpoint_apps
        post :stop_all_server_endpoint_apps
        post :destroy_all_server_endpoint_apps
        post :stop_all_server_endpoint_apps
        post :status_all_server_endpoint_apps

        post :create_all_worker_endpoint_apps
        post :configure_all_worker_endpoint_apps
        post :start_all_worker_endpoint_apps
        post :restart_all_worker_endpoint_apps
        post :deploy_all_worker_endpoint_apps
        post :stop_all_worker_endpoint_apps
        post :destroy_all_worker_endpoint_apps
        post :stop_all_worker_endpoint_apps
        post :status_all_worker_endpoint_apps

        get  :partial_status
        post :clear_log

        delete :delete
      end
      resources :server_endpoints, :controller => "frontends/backends/server_endpoint" do
        member do
          post   :clear_log
          post   :create_app
          post   :configure_app
          post   :start_app
          post   :restart_app
          post   :stop_app
          post   :deploy_app
          delete :destroy_app
          post   :remote_status
          get    :partial_status
          post   :get_logs
          get    :remote_log
          post   :truncate_remote_logs
        end
      end
      resources :worker_endpoints, :controller => "frontends/backends/worker_endpoint" do
        member do
          post   :clear_log
          post   :create_app
          post   :configure_app
          post   :start_app
          post   :restart_app
          post   :stop_app
          post   :deploy_app
          delete :destroy_app
          post   :remote_status
          get    :partial_status
          post   :get_logs
          get    :remote_log
          post   :truncate_remote_logs
        end
      end
    end
  end
  # For destroy
  resources :backends
  resources :remote_keys, :except => [:edit, :update]
  resources :deploy_heroku_api_keys
  resources :delayed_jobs, :only => [:index, :destroy, :destroy_all] do
    collection do
      delete "destroy_all"
    end
  end
end
