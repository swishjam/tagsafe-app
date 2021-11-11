# module LambdaModerator
#   module Receivers
#     class IndividualPerformanceAuditCompleted
#       def initialize(
#         individual_performance_audit_id:, 
#         results:,
#         logs:,
#         error:,
#         blocked_tag_urls:,
#         allowed_tag_urls:,
#         aws_log_stream_name:,
#         aws_request_id:,
#         aws_trace_id:,
#         page_load_screenshot_urls:,
#         page_load_trace_json_url:
#       )
#         @individual_performance_audit_id = individual_performance_audit_id
#         @results = results
#         @logs = logs
#         @blocked_tag_urls = blocked_tag_urls
#         @allowed_tag_urls = allowed_tag_urls
#         @aws_log_stream_name = aws_log_stream_name
#         @aws_request_id = aws_request_id
#         @aws_trace_id = aws_trace_id
#         @page_load_screenshot_urls = page_load_screenshot_urls
#         @page_load_trace_json_url = page_load_trace_json_url
#         @error = error
#       end

#       def evaluate_results!
#         if evaluator.already_processed?
#           Rails.logger.warn "Already processed IndividualPerformanceAudit #{individual_performance_audit_id}, bypassing..."
#         else
#           evaluator.evaluate!
#           finalize_audit! if all_individual_performance_audit_completed?
#         end
#       end

#       private

#       def all_individual_performance_audit_completed?
#         !audit.performance_audit_failed? && audit.all_individual_performance_audits_completed?
#       end

#       def finalize_audit!
#         audit.create_delta_performance_audit!
#         audit.completed!
#       end

#       def evaluator
#         @evaluator ||= PerformanceAuditManager::ResultsCapturer.new(
#           individual_performance_audit_id: @individual_performance_audit_id,
#           results: @results,
#           blocked_tag_urls: @blocked_tag_urls,
#           allowed_tag_urls: @allowed_tag_urls,
#           aws_log_stream_name: @aws_log_stream_name,
#           aws_request_id: @aws_request_id,
#           aws_trace_id: @aws_trace_id,
#           logs: @logs,
#           page_load_screenshot_urls: @page_load_screenshot_urls,
#           page_load_trace_json_url: @page_load_trace_json_url,
#           error: @error
#         )
#       end

#       def audit
#         @audit ||= evaluator.individual_performance_audit.audit
#       end
#     end
#   end
# end