

BuspassDeployer::Application.routes.draw do
  resources :installations  do
    member do
      get :edit_frontend_git
      get :edit_server_endpoint_git
      get :edit_swift_endpoint_git
      get :edit_worker_endpoint_git
      put :update_frontend_git
      put :update_server_endpoint_git
      put :update_swift_endpoint_git
      put :update_worker_endpoint_git
      post :install_frontends
      post :start_frontends
      post :upgrade
      post :start
      post :stop
      post :clear_log
      get  :status
      get  :partial_status
      post :ping_remote_status
      get :deploy_status
      get  :partial_deploy_status
    end
  end

  resources :frontends do
    member do
      post   :configure
      post   :deconfigure
      post   :start
      post   :stop
      post   :install
      post   :upgrade
      get    :upload_key
      put    :store_key
      post   :full_configure
      delete :destroy_backends
      post :clear_log
      post :create_all_endpoint_apps
      post :configure_all_endpoint_apps
      post :start_all_endpoint_apps
      post :restart_all_endpoint_apps
      post :stop_all_endpoint_apps
      post :deploy_all_endpoint_apps
      post :destroy_all_endpoint_apps
    end
    resources :backends, :controller => "frontends/backends" do
      collection do
        get :new_base
        post :start_all
        post :restart_all
        post :stop_all
        post :status_all
        get :status_all
        get :partial_status_all
        get  :edit_software
        post :update_software
        get  :frontend_partial_status
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
        post :create_all_swift_endpoint_apps
        post :configure_all_swift_endpoint_apps
        post :start_all_swift_endpoint_apps
        post :restart_all_swift_endpoint_apps
        post :deploy_all_swift_endpoint_apps
        post :stop_all_swift_endpoint_apps
        post :destroy_all_swift_endpoint_apps
        post :stop_all_swift_endpoint_apps
        post :status_all_swift_endpoint_apps
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
      resources :swift_endpoints, :controller => "frontends/backends/swift_endpoint" do
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
end
