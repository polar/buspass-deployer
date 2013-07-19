
rake: bundle exec rake jobs:work QUEUE=deploy-web
work: bundle exec script/delayed_job -queue=deploy-web run
deploy: bundle exec script/delayed_job -queue=deploy-web run


