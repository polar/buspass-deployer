
#
# To encrypt any keys we use the this key which is in the environment.
#

Encryptor.default_options.merge!(:key => ENV["SECRET_ENCRYPTION_KEY"])