class PerformanceAuditCalculator < ApplicationRecord
  belongs_to :domain
  has_many :performance_audits

  DEFAULT_WEIGHTS = {
    dom_complete_weight: 0.15,
    dom_content_loaded_weight: 0.15,
    dom_interactive_weight: 0.15,
    first_contentful_paint_weight: 0.15,
    layout_duration_weight: 0.1,
    task_duration_weight: 0.1,
    script_duration_weight: 0.1,
    byte_size_weight: 0.1
  }

  # deduct n points of 100 for each metric: Impact Score / METRIC_SCORE_INCREMENTS
  # a DOMComplete impact of 100ms would be a deduction of 2 points
  DEFAULT_DECREMENTS = {
    dom_complete_score_decrement_amount: 15,
    dom_content_loaded_score_decrement_amount: 15,
    dom_interactive_score_decrement_amount: 15,
    first_contentful_paint_score_decrement_amount: 15,
    task_duration_score_decrement_amount: 5,
    layout_duration_score_decrement_amount: 5,
    script_duration_score_decrement_amount: 5,
    byte_size_score_decrement_amount: 20_000
  }

  scope :currently_active, -> { where(currently_active: true) }
  scope :currently_inactive, -> { where(currently_active: false) }
  scope :active, -> { currently_active }
  scope :inactive, -> { currently_inactive }

  validate :only_one_active
  validate :sum_of_weights_equal_100

  def self.create_default_calculator(domain, active = true)
    default_args = { domain_id: domain.id, currently_active: active }
    default_args.merge!(DEFAULT_DECREMENTS.merge(DEFAULT_WEIGHTS))
    create!(default_args)
  end

  def make_active
    domain.current_performance_audit_calculator.update!(currently_active: false)
    update!(currently_active: true)
  end

  private

  def only_one_active
    if domain.performance_audit_calculators.active.count > 1
      errors.add(:base, "Only one active PerformanceAuditCalculator allowed per domain.")
    end
  end

  def sum_of_weights_equal_100
    sum_of_weights = dom_complete_weight + 
                        dom_content_loaded_weight + 
                        dom_interactive_weight + 
                        first_contentful_paint_weight + 
                        layout_duration_weight + 
                        task_duration_weight + 
                        script_duration_weight + 
                        byte_size_weight
    if sum_of_weights < 99.999 || sum_of_weights > 100.0001
      errors.add(:base, "Weights must add up to 100")
    end
  end
end
