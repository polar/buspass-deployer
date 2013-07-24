
bundle exec script/delayed_job --queues=deploy-web -i 1 start
bundle exec script/delayed_job --queues=deploy-web -i 2 start
bundle exec script/delayed_job --queues=deploy-web -i 3 start
bundle exec script/delayed_job --queues=deploy-web -i 4 start
bundle exec script/delayed_job --queues=deploy-web -i 5 start
bundle exec script/delayed_job --queues=deploy-web -i 6 run