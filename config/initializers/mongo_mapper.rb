##
# BusPass MongoDB Configuration
#
# This MongoDB configuration applies to using MONGOLAB on Heroku, and locally.
#
#
require 'uri'
require 'mongo'
require 'mongo_mapper'

if ENV['MONGOLAB_URI']

  # We are on Heroku and using MONGOLAB for a MongoDB

  uri  = URI.parse(ENV['MONGOLAB_URI'])
  puts "Connecting to MONGOLAB_URI #{uri}"
  puts "MONGOLAB Database Name #{uri.path.gsub(/^\//, '')}"
  MongoMapper.connection = conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI']) #, :logger => Rails.logger
  MongoMapper.database = (uri.path.gsub(/^\//, ''))

else

  # Local Configuration

  MongoMapper.connection = Mongo::Connection.new('localhost', 27017, :logger => Rails.logger)
  MongoMapper.database = "#Busme-#{Rails.env}"

end
MongoMapper::Plugins::IdentityMap.enabled = true

#
# Heroku uses Passenger, and we need to connect to the MongoDB when
# we are forked.
#
# NOTE: I'm not sure why that doesn't happen automatically.
#

if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end
