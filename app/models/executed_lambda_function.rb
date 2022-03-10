class ExecutedLambdaFunction < ApplicationRecord
  uid_prefix 'lam'

  belongs_to :parent, polymorphic: true
  store :request_payload
  store :response_payload

  scope :failed, -> { where.not(response_code: 202) }
  scope :successful, -> { where(response_code: 202) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending_response, -> { where(completed_at: nil) }
  scope :pending, -> { pending_response }

  validate :parent_doesnt_already_have_executed_lambda_function, on: :create

  def self.for(obj)
    find_by(parent: obj)
  end

  def response_received!(response_code: 202, response_payload:)
    if already_received_response?
      Rails.logger.warn "Received response for ExecutedLambdaFunction #{id} (#{parent_type} Parent #{parent_id}) that was already received, skipping...."
    else
      update!(
        completed_at: Time.now,
        response_code: response_code,
        response_payload: response_payload,
        aws_log_stream_name: response_payload.dig('detail', 'responsePayload', 'aws_log_stream_name'),
        aws_request_id: response_payload.dig('detail', 'responsePayload', 'aws_request_id'),
        aws_trace_id: response_payload.dig('detail', 'responsePayload', 'aws_trace_id')
      )
      ProcessReceivedLambdaEventJob.perform_later(response_payload)
    end
  end

  def completed?
    !pending?
  end
  alias received_response? completed?
  alias already_received_response? completed?

  def pending?
    completed_at.nil?
  end

  def successful?
    response_code == 202
  end

  def failed?
    !successful?
  end

  private

  def parent_doesnt_already_have_executed_lambda_function
    if parent.executed_lambda_function
      errors.add(:base, "Parent already has an ExecutedLambdaFunction.")
    end
  end
end