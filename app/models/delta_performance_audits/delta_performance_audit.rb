class DeltaPerformanceAudit < ApplicationRecord
  belongs_to :audit, optional: true
  belongs_to :performance_audit_with_tag, foreign_key: :performance_audit_with_tag_id, class_name: PerformanceAudit.to_s
  belongs_to :performance_audit_without_tag, foreign_key: :performance_audit_without_tag_id, class_name: PerformanceAudit.to_s

  scope :outliers, -> { where(is_outlier: true) }
  scope :not_outliers, -> { where(is_outlier: false) }

  TAGSAFE_SCORE_THRESHOLDS = { good: 90, warn: 80 }
  CHARTABLE_COLUMNS = [
    { title: 'Tagsafe Score', column: :tagsafe_score }, 
    { title: 'Main Thread Execution', column: :main_thread_execution_tag_responsible_for_delta },
    { title: 'Speed Index', column: :speed_index_delta },
    { title: 'DOM Complete', column: :dom_complete_delta }, 
    { title: 'DOM Interactive', column: :dom_interactive_delta }, 
    { title: 'First Contentful Paint', column: :first_contentful_paint_delta }, 
    { title: 'DOM Content Loaded', column: :dom_content_loaded_delta }, 
    { title: 'Script Duration', column: :script_duration_delta }, 
    { title: 'Layout Duration', column: :layout_duration_delta }, 
    { title: 'Task Duration', column: :task_duration_delta }
  ].freeze

  def self.TYPES
    %w[
      AverageDeltaPerformanceAudit
      IndividualDeltaPerformanceAudit
      MedianDeltaPerformanceAudit
    ]
  end

%i[
    speed_index dom_complete dom_content_loaded dom_interactive first_contentful_paint script_duration task_duration layout_duration
  ].each do |metric|
    define_method(metric){ send(:"#{metric}_delta") }
    define_method(:"#{metric}_percentage"){ ((send(metric)/performance_audit_with_tag.send(metric))*100).round(2) }
  end

  def main_thread_execution_tag_responsible_for
    main_thread_execution_tag_responsible_for_delta
  end

  def main_thread_execution_tag_responsible_for_percentage
    ((main_thread_execution_tag_responsible_for / entire_main_thread_execution_ms_delta)*100).round(2)
  end

  def main_thread_blocking_execution_tag_responsible_for
    main_thread_blocking_execution_tag_responsible_for_delta
  end

  def main_thread_blocking_execution_tag_responsible_for_percentage
    ((main_thread_blocking_execution_tag_responsible_for / entire_main_thread_blocking_executions_ms_delta)*100).round(2)
  end

  def tagsafe_score_metric_deduction(performance_metric)
    tagsafe_scorer.performance_metric_deduction(performance_metric)
  end

  def <=>(comparable)
    tagsafe_score <=> comparable.tagsafe_score
  end

  private

  def tagsafe_scorer
    @tagsafe_scorer ||= TagsafeScorer.new(
      performance_audit_calculator: audit.performance_audit_calculator, 
      dom_complete_delta: dom_complete_delta,
      dom_content_loaded_delta: dom_content_loaded_delta, 
      dom_interactive_delta: dom_interactive_delta, 
      first_contentful_paint_delta: first_contentful_paint_delta, 
      task_duration_delta: task_duration_delta, 
      script_duration_delta: script_duration_delta, 
      layout_duration_delta: layout_duration_delta,
      speed_index_delta: speed_index_delta, 
      perceptual_speed_index_delta: perceptual_speed_index_delta, 
      main_thread_execution_tag_responsible_for_delta: main_thread_execution_tag_responsible_for_delta, 
      main_thread_blocking_execution_tag_responsible_for_delta: main_thread_blocking_execution_tag_responsible_for_delta, 
      entire_main_thread_execution_ms_delta: entire_main_thread_execution_ms_delta, 
      entire_main_thread_blocking_executions_ms_delta: entire_main_thread_blocking_executions_ms_delta,
      ms_until_first_visual_change_delta: ms_until_first_visual_change_delta, 
      ms_until_last_visual_change_delta: ms_until_last_visual_change_delta,
      byte_size: bytes
    )
  end
end