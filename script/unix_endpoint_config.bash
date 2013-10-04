#
# This script is not meant to be executed
# It is merely just a note of what needs to be done on an endpoint machine as root
# Before we can have the deployer deploy Endpoints (Swift, Worker, or Api) we must
# prep the system.
#

#
# Add RVM for all users. You must not be the root user when doing this action
#
su - admin '/usr/bin/curl -L https://get.rvm.io | sudo bash'

#
# Need some extra libraries to get Busme! running
#
adduser admin

apt-get install build-essential libcurl4-gnutils-dev   rmagic   libmagick++-dev  libgsl0-dev nodejs git

#
# The Busme! Deployer needs to create users on the endpoint machines
#
adduser uadmin --ingroup admin

#
# The deployer will sudo as uadmin to add/delete users and needs only the following
# commands to be enabled. Put the following cat content in the sudoers file or
# in the sudoers.d direction. If so, remember to enable reading from the /etc/sudoers.d
# directory.
#
cat > /etc/sudoers.d/uadmin <<EOF
Defaults !requiretty
uadmin ALL=(ALL:ALL) NOPASSWD: /usr/sbin/adduser, /user/sbin/deluser, /usr/sbin/delgroup, /usr/bin/addgroup, /bin/ls, /bin/cp, /bin/mkdir, /bin/rm, /bin/cat, /bin/chmod, /bin/chown, /usr/bin/tee
EOF


su - uadmin mkdir .ssh
chmod 700 .ssh
cat > .ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4SkAS1ob2mNoyGnHShWramjOWCPkBfJl4x/DWfVxsP3Y7WZwwCriQPUT9btuWQRMOsZqeWFtLssbNBnDVNsBj3/551Pr9sGqK+pN+/Eyr41G90ukIbkC9wOGRh7q1MQNGkhjaABWTG3h3e+v7NGiPmycqbJNGrxr74gh0Rs/T9Iv7oukdSo0jmoodIjpCRn9Q6QFY8y2Ps8UTz3MPqMitRCyVNiyb2+8LXBqoFWZMqIOt3NNRXfdkpU+JORLSZd8FD6T/erqVyJiRna72OzSPUapbX8X5EtKXxUGRwPwDv+dihnyv/3emWv9byQcFHRBqU67SU4Nrc0X+i2zSLpBF
EOF
