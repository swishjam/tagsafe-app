web: bundle exec rails server
scheduled_audit_queue: INTERVAL=0.5 QUEUE=scheduled_audit_queue bundle exec rake resque:work
lambda_results: INTERVAL=0.1 QUEUE=lambda_results bundle exec rake resque:work
worker: INTERVAL=0.1 QUEUE=critical,normal,low,default bundle exec rake resque:work
resque_scheduler: bundle exec rake resque:scheduler

release: rails db:migrate

# dev_worker: INTERVAL=0.1 QUEUE=critical,scheduled_audit_queue,lambda_results,normal,low,default bundle exec rake resque:work