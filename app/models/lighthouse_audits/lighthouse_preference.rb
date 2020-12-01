class LighthousePreference < ApplicationRecord
  belongs_to :script_subscriber

  def self.create_default!(script_subscriber)
    LighthousePreference.create!(
      script_subscriber: script_subscriber,
      should_run_audit: false, 
      url_to_audit: script_subscriber.domain.url,
      num_test_iterations: 3, 
      should_capture_individual_audit_metrics: false,
      performance_impact_threshold: 0.1
    )
  end

  def formatted_performance_impact_threshold
    (performance_impact_threshold*100).round(2)
  end
end