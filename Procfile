web: bundle exec rails server
default_queue: QUEUE=default bundle exec rake resque:work
performance_audit_runner_queue: QUEUE=performance_audit_runner_queue bundle exec rake resque:work
tag_checker_queue: QUEUE=tag_checker_queue bundle exec rake resque:work
crawl_url_for_tags_queue: QUEUE=crawl_url_for_tags_queue bundle exec rake resque:work
resque_scheduler: bundle exec rake resque:scheduler