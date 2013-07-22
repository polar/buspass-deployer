bundle exec script/delayed_job -i 1 stop
bundle exec script/delayed_job -i 2 stop
bundle exec script/delayed_job -i 3 stop
bundle exec script/delayed_job -i 4 stop
sleep 10
bundle exec script/delayed_job --queues=deploy-web -i 1 start
bundle exec script/delayed_job --queues=deploy-web -i 2 start
bundle exec script/delayed_job --queues=deploy-web -i 3 start
bundle exec script/delayed_job --queues=deploy-web -i 4 run