source 'https://rubygems.org'
ruby "1.9.3"

gem 'rails', '3.2.11'
gem 'rake'
gem "rack", "1.4.0"
gem "rack-cache", "1.2"

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# The following gems are for using MongoMapper ORM

gem "bson_ext"#, ">= 1.3.1"
gem "mongo_mapper"

# The following gems are used to handle file uploads. We use Carrierwave
# to handle the uploads of PlanFiles, so they get uploaded directly (on Heroku)
# and go away later as we do not keep them.

gem "carrierwave"
gem "mm-carrierwave"   # Using the MongoMapper ORM

gem "devise", "2.1.0"
gem 'devise-mongo_mapper', :git => "git://github.com/polar/devise-mongo_mapper"

# For encryption

gem "encryptor"

# The following gems are required for handling background
# processing.

#gem "delayed_job", :path => "/home/polar/src/delayed_job"
gem "delayed_job", :git => "git://github.com/polar/delayed_job.git"
gem "delayed_job_mongo_mapper", :git => "git://github.com/polar/delayed_job_mongo_mapper.git"
gem "daemons"
gem "rush"

gem "heroku-api"
gem "heroku-headless", :git => "git://github.com/polar/heroku-headless.git" # :path => "/home/polar/src/heroku-headless"


gem "client_side_validations"
gem "client_side_validations-mongo_mapper"

group :assets do
  gem 'sass-rails'#,   '~> 3.2.4'
  gem 'coffee-rails'#, '~> 3.2.2'
  gem 'uglifier'#, '>= 1.2.3'
  gem 'asset_sync'
  gem "remotipart"
end

gem 'compass-rails'

# I'm not sure if this gem is needed with Rails 3.2.3

# Causes non-termination of bundle update
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'spinjs-rails'

gem 'newrelic_rpm'
gem 'newrelic_mongo'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

gem 'net-ssh', '2.7.0'
gem "fog", "1.8.0"