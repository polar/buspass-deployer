
# Creds here is just for local development. This file does not exist in production environment.
# We need this here for the locally run rake assets::precompile or any rake task.
creds = File.expand_path("../aa_creds.rb", File.dirname(__FILE__))
require creds if File.exists?(creds)