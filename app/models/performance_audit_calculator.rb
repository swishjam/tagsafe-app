class PerformanceAuditCalculator < ApplicationRecord
  belongs_to :container
  has_many :audits, dependent: :restrict_with_error

  before_destroy :ensure_can_destroy, prepend: true

  scope :currently_active, -> { where(currently_active: true) }
  scope :currently_inactive, -> { where(currently_active: false) }
  scope :active, -> { currently_active }
  scope :inactive, -> { currently_inactive }

  validate :only_one_active
  validate :sum_of_weights_equal_100

  DEFAULT_WEIGHTS = {
    dom_complete_weight: 0.1,
    dom_content_loaded_weight: 0.1,
    dom_interactive_weight: 0.1,
    first_contentful_paint_weight: 0.1,
    speed_index_weight: 0.1,
    main_thread_execution_tag_responsible_for_weight: 0.3,
    layout_duration_weight: 0.05,
    task_duration_weight: 0.05,
    script_duration_weight: 0.05,
    byte_size_weight: 0.05,
    perceptual_speed_index_weight: 0,
    ms_until_first_visual_change_weight: 0,
    ms_until_last_visual_change_weight: 0
  }

  # deduct n points of 100 for each metric: (Metric Value / Decrement Amount) * Weight
  # An audit with:
  #    Speed Index = 1,000 ms
  #    Speed Index Weight = 0.1 (10%)
  #    Speed Index Decrement Amount = 10
  # Results in a score deduction of 10 ((1,000 / 10)*0.1)
  DEFAULT_DECREMENTS = {
    dom_complete_score_decrement_amount: 15,
    dom_content_loaded_score_decrement_amount: 15,
    dom_interactive_score_decrement_amount: 15,
    first_contentful_paint_score_decrement_amount: 15,
    speed_index_score_decrement_amount: 15,
    main_thread_execution_tag_responsible_for_score_decrement_amount: 10,
    task_duration_score_decrement_amount: 5,
    layout_duration_score_decrement_amount: 5,
    script_duration_score_decrement_amount: 5,
    byte_size_score_decrement_amount: 20_000,
    perceptual_speed_index_score_decrement_amount: 0,
    ms_until_first_visual_change_score_decrement_amount: 0,
    ms_until_last_visual_change_score_decrement_amount: 0
  }

  def self.create_default(container, active = true)
    default_args = { container_id: container.id, currently_active: active }
    default_args.merge!(DEFAULT_DECREMENTS.merge(DEFAULT_WEIGHTS))
    create!(default_args)
  end

  def active?
    currently_active
  end
  alias currently_active? active?

  def make_active
    container.current_performance_audit_calculator.update!(currently_active: false)
    update!(currently_active: true)
  end

  private

  def ensure_can_destroy
    ensure_inactive_on_destroy
    ensure_no_past_audits_on_destroy
    throw(:abort) unless valid?
  end

  def ensure_no_past_audits_on_destroy
    if audits.any?
      errors.add(:base, "Cannot destroy a Performance Audit Calculator that has past audits tied to it.")
    end
  end

  def ensure_inactive_on_destroy
    if currently_active?
      errors.add(:base, "Cannot destroy a Performance Audit Calculator that is currently active.")
    end
  end

  def only_one_active
    if container.performance_audit_calculators.active.count > 1
      errors.add(:base, "Only one active PerformanceAuditCalculator allowed per container.")
    end
  end

  def sum_of_weights_equal_100
    sum_of_weights = dom_complete_weight + 
                        dom_content_loaded_weight + 
                        dom_interactive_weight + 
                        first_contentful_paint_weight + 
                        speed_index_weight +
                        main_thread_execution_tag_responsible_for_weight +
                        layout_duration_weight + 
                        task_duration_weight + 
                        script_duration_weight + 
                        byte_size_weight +
                        perceptual_speed_index_weight +
                        ms_until_first_visual_change_weight +
                        ms_until_last_visual_change_weight
    if sum_of_weights < 0.999 || sum_of_weights > 1.0001
      errors.add(:base, "Weights must add up to 100")
    end
  end
end
