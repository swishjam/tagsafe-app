# class SuccessfulLambdaFunctionReceiverJob < ApplicationJob
#   queue_as :lambda_receiver_queue

#   def perform(lambda_response_body)
#     evaluate_results_from_lambda_function_response(lambda_response_body)
#   end

#   def evaluate_results_from_lambda_function_response(lambda_function_response)
#     lambda_function_received = lambda_function_response['type']
#     case lambda_function_received
#     when 'UrlCrawl'
#       evaluate_url_crawl!(lambda_function_response)
#     when 'PerformanceAudit'
#       evaluate_performance_audit!(lambda_function_response)
#     else
#       raise InvalidLambdaFunctionType, "Unrecognized Lambda function received: #{lambda_function_received}"
#     end
#   end

#   def evaluate_url_crawl!(lambda_function_response)
#     LambdaModerator::Receivers::UrlCrawlCompleted.new(
#       tag_urls: lambda_function_response['tag_urls'],
#       url_crawl_id: lambda_function_response['url_crawl_id'],
#       error_message: lambda_function_response['error_message'],
#       initial_crawl: lambda_function_response['initial_crawl'],
#       aws_log_stream_name: lambda_function_response['aws_log_stream_name'],
#       aws_request_id: lambda_function_response['aws_request_id'],
#       aws_trace_id: lambda_function_response['aws_trace_id']
#     ).evaluate_results!
#   end

#   def evaluate_performance_audit!(lambda_function_response)
#     LambdaModerator::Receivers::IndividualPerformanceAuditCompleted.new(
#       individual_performance_audit_id: lambda_function_response['individual_performance_audit_id'], 
#       results: lambda_function_response['results'],
#       logs: lambda_function_response['logs'],
#       error: lambda_function_response['error'],
#       blocked_tag_urls: lambda_function_response['third_party_tags_blocked'],
#       allowed_tag_urls: lambda_function_response['third_party_tags_allowed'],
#       aws_log_stream_name: lambda_function_response['aws_log_stream_name'],
#       aws_request_id: lambda_function_response['aws_request_id'],
#       aws_trace_id: lambda_function_response['aws_trace_id'],
#       page_load_screenshot_urls: lambda_function_response['page_load_screenshots'],
#       page_load_trace_json_url: lambda_function_response['trace_json_s3_location']
#     ).evaluate_results!
#   end
# end