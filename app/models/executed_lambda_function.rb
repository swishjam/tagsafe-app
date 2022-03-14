class ExecutedLambdaFunction < ApplicationRecord
  uid_prefix 'lam'

  belongs_to :parent, polymorphic: true
  store :request_payload
  store :response_payload

  scope :failed, -> { where.not(response_code: 202) }
  scope :successful, -> { where(response_code: 202) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending_response, -> { where(completed_at: nil).where.not(executed_at: nil) }
  scope :pending, -> { pending_response }
  scope :potentially_never_responded, -> { pending.where('executed_at < ?', 10.minutes.ago) }

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
        ms_to_receive_response: Time.now - executed_at,
        response_code: response_code,
        response_payload: response_payload,
        aws_log_stream_name: response_payload['aws_log_stream_name'],
        aws_request_id: response_payload['aws_request_id'],
        aws_trace_id: response_payload['aws_trace_id']
      )
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