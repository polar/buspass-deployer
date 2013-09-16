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
apt-get install libcurl4-gnutils-dev
apt-get install rmagic
apt-get install libmagick++-dev
apt-get install libgsl0-dev
apt-get isntall nodejs

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