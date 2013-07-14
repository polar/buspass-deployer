#
# BusPass DelayedJob configurqation
#
# Although the gem takes care of this, these settings in an
# initializer are needed for the script/delayed_job and rake jobs:start
Delayed::Worker.backend= :mongo_mapper

#
# We only want one attempt.
#  TODO: Fix Delayed job so that this is not an automatic ability.
#
# This number means max "retry" attempts.
Delayed::Worker.max_attempts=1
# We don't want long running jobs dying. The default is 4.hours.
Delayed::Worker.max_run_time = 2.years

#
# Workless 1.0.1 Gem
#    We do not use Workless any more to spin up workers.
#    We might have to once we move to Heroku, since it requires Active::Record.
#
#
# We use MongoMapper so, we need this for the autoscaler.
# This autoscaler spins up local processess on its own, without the need
# for the workless gem.
#
# NOTE: 2012-08-22 - This works on Heroku, but not quite sure of the performance and financial ramifications.
#
#Delayed::Backend::MongoMapper::Job.send(:include, MasterScaler) if defined?(Delayed::Backend::MongoMapper::Job)

