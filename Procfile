web: bundle exec rails server
# tag_checker_queue: INTERVAL=0.5 QUEUE=tag_checker_queue bundle exec rake resque:work
# performance_audit_runner_queue: INTERVAL=0.5 QUEUE=performance_audit_runner_queue bundle exec rake resque:work
# functional_tests_queue: INTERVAL=0.5 QUEUE=functional_tests_queue bundle exec rake resque:work
# default_queue: INTERVAL=0.5 QUEUE=default bundle exec rake resque:work
# crawl_url_for_tags_queue: QUEUE=crawl_url_for_tags_queue bundle exec rake resque:work
scheduled_audit_queue: INTERVAL=0.5 QUEUE=scheduled_audit_queue bundle exec rake resque:work
worker: INTERVAL=0.1 QUEUE=critical,normal,low,default bundle exec rake resque:work
resque_scheduler: bundle exec rake resque:scheduler