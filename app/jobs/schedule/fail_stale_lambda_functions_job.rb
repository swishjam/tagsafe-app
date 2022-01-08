# module Schedule
#   class FailStaleLambdaFunctionsJob < ApplicationJob
#     def perform
#       audits_to_purge = Audit.pending_performance_audit.older_than(performance_audit_fail_minutes.minutes.ago)
#       Resque.logger.info "Purging #{audits_to_purge.count} Audits that exceed #{performance_audit_fail_minutes} minute fail period."
#       audits_to_purge.each do |audit|
#         audit.performance_audit_error!("Audit never completed within #{performance_audit_fail_minutes} minutes.")
#       end
      
#       url_crawls_to_purge = UrlCrawl.pending.older_than(url_crawl_fail_minutes.minutes.ago, timestamp_column: :enqueued_at)
#       Resque.logger.info "Purging #{url_crawls_to_purge.count} UrlCrawls that exceed #{url_crawl_fail_minutes} minute fail period"
#       url_crawls_to_purge.each do |crawl|
#         crawl.errored!("Crawl never completed after #{url_crawl_fail_minutes} minutes.")
#       end
#     end

#     def performance_audit_fail_minutes
#       (ENV['FAIL_STALE_PENDING_MINUTES_AGO'] || 60).to_i
#     end

#     def url_crawl_fail_minutes
#       (ENV['FAIL_STALE_URL_CRAWL_MINUTES_AGO'] || 15).to_i
#     end
#   end
# end