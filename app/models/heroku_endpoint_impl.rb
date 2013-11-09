module HerokuEndpointImpl
  key :heroku_app_name_store

  def heroku_app_name
    heroku_app_name_store || name
  end
end