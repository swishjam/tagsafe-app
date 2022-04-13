web: bundle exec rails server
scheduled_audit_queue: INTERVAL=0.5 QUEUE=scheduled_audit_queue bundle exec rake resque:work
worker: INTERVAL=0.1 QUEUE=critical,normal,low,default bundle exec rake resque:work
resque_scheduler: bundle exec rake resque:scheduler