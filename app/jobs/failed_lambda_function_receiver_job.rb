# class FailedLambdaFunctionReceiverJob < ApplicationJob
#   queue_as :lambda_receiver_queue

#   def perform(individual_performance_audit_id, response_data)
#     individual_performance_audit = IndividualPerformanceAudit.find(individual_performance_audit_id)
#     individual_performance_audit.error!(response_data['errorMessage'])
#   end
# end