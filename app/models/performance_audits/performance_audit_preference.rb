class PerformanceAuditPreference < ApplicationRecord
  belongs_to :script_subscriber

  def self.create_default(script_subscriber)
    create(
      script_subscriber: script_subscriber,
      num_test_iterations: 3,
      should_run_audit: true,
      url_to_audit: script_subscriber.domain.url
    )
  end
end