web: bundle exec rails server
# scheduled_audit_queue: INTERVAL=0.5 QUEUE=scheduled_audit_queue bundle exec rake resque:work
lambda_results: INTERVAL=0.1 QUEUE=lambda_results bundle exec rake resque:work
worker: INTERVAL=0.1 QUEUE=critical,normal,low,default bundle exec rake resque:work
tagsafe_js_events: INTERVAL=0.1 QUEUE=tagsafe_js_events bundle exec rake resque:work
resque_scheduler: bundle exec rake resque:scheduler

# release: rails db:migrate

# dev_worker: INTERVAL=0.1 QUEUE=tagsafe_js_events,lambda_results,critical,normal,low,default bundle exec rake resque:work