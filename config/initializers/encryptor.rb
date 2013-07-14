
# To encrypt the private keys we use the
# Heroku API key, since we will be using it only from
# Heroku instances
#

Encryptor.default_options.merge!(:key => ENV["HEROKU_API_KEY"])