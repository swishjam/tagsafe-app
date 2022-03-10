class Audit < ApplicationRecord
  include Streamable
  uid_prefix 'aud'
  acts_as_paranoid

  belongs_to :initiated_by_domain_user, class_name: DomainUser.to_s, optional: true
  belongs_to :tag_version
  belongs_to :tag
  belongs_to :execution_reason
  belongs_to :page_url
  belongs_to :performance_audit_calculator

  has_one :performance_audit_configuration, dependent: :destroy
  accepts_nested_attributes_for :performance_audit_configuration

  has_many :performance_audits, dependent: :destroy
  
  has_many :individual_performance_audits_with_tag, class_name: IndividualPerformanceAuditWithTag.to_s
  has_many :individual_performance_audits_without_tag, class_name: IndividualPerformanceAuditWithoutTag.to_s
  has_many :individual_performance_audits, -> { 
      where(type: [
        IndividualPerformanceAuditWithTag.to_s, 
        IndividualPerformanceAuditWithoutTag.to_s
      ]) 
    }, class_name: PerformanceAudit.to_s

  has_one :median_individual_performance_audit_with_tag, class_name: MedianIndividualPerformanceAuditWithTag.to_s
  has_one :median_individual_performance_audit_without_tag, class_name: MedianIndividualPerformanceAuditWithoutTag.to_s
  
  has_many :individual_and_median_performance_audits, -> { 
      where(type: [
          MedianIndividualPerformanceAuditWithTag.to_s, 
          MedianIndividualPerformanceAuditWithoutTag.to_s, 
          IndividualPerformanceAuditWithTag.to_s,
          IndividualPerformanceAuditWithoutTag.to_s
        ]) 
      }, class_name: PerformanceAudit.to_s
  has_many :individual_and_median_performance_audits_with_tag, -> { 
      where(type: [
        MedianIndividualPerformanceAuditWithTag.to_s, 
        IndividualPerformanceAuditWithTag.to_s
      ]) 
    }, class_name: PerformanceAudit.to_s
  has_many :individual_and_median_performance_audits_without_tag, -> { 
      where(type: [
        MedianIndividualPerformanceAuditWithoutTag.to_s, 
        IndividualPerformanceAuditWithoutTag.to_s
      ]) 
    }, class_name: PerformanceAudit.to_s

  has_one :average_performance_audit_with_tag, class_name: AveragePerformanceAuditWithTag.to_s
  has_one :average_performance_audit_without_tag, class_name: AveragePerformanceAuditWithoutTag.to_s

  has_many :delta_performance_audits, dependent: :destroy
  has_one :average_delta_performance_audit, class_name: AverageDeltaPerformanceAudit.to_s
  has_one :median_delta_performance_audit, class_name: MedianDeltaPerformanceAudit.to_s
  has_many :individual_delta_performance_audits, class_name: IndividualDeltaPerformanceAudit.to_s
  # has_many :all_delta_performance_audits, -> { 
  #     where(type: [
  #       AverageDeltaPerformanceAudit.to_s, 
  #       MedianDeltaPerformanceAudit.to_s, 
  #       IndividualDeltaPerformanceAudit.to_s
  #     ]) 
  #   }, class_name: DeltaPerformanceAudit.to_s

  has_many :test_runs, dependent: :destroy
  has_many :test_runs_with_tag, class_name: TestRunWithTag.to_s
  has_many :test_runs_without_tag, class_name: TestRunWithoutTag.to_s

  has_one :page_change_audit, class_name: PageChangeAudit.to_s, dependent: :destroy

  validate :has_at_least_one_type_of_audit_enabled

  after_create_commit -> { prepend_audit_to_list(audit: self, now: true) }
  after_create_commit :enqueue_configured_audit_types

  ##########
  # SCOPES #
  ##########

  scope :primary, -> { where(primary: true) }
  scope :not_primary, -> { where(primary: false) }

  scope :completed, -> { where.not(seconds_to_complete: nil) }
  scope :pending, -> { where(seconds_to_complete: nil) }

  scope :throttled, -> { where(throttled: true) }
  scope :not_throttled, -> { where(throttled: false) }

  scope :performance_audits_disabled, -> { where(include_performance_audit: false) }
  scope :performance_audits_enabled, -> { where(include_performance_audit: true) }
  scope :pending_performance_audit, -> { performance_audits_enabled.where(performance_audit_completed_at: nil) }
  scope :completed_performance_audit, -> { performance_audits_enabled.where.not(performance_audit_completed_at: nil) }
  scope :successful_performance_audit, -> { completed.where(performance_audit_error_message: nil) }
  scope :failed_performance_audit, -> { where.not(performance_audit_error_message: nil) }

  scope :functional_tests_disabled, -> { where(include_functional_tests: false) }
  scope :functional_tests_enabled, -> { where(include_functional_tests: true) }
  scope :pending_functional_tests, -> { functional_tests_enabled.where(functional_tests_completed_at: nil ) }
  scope :completed_functional_tests, -> { functional_tests_enabled.where.not(functional_tests_completed_at: nil ) }

  scope :page_change_audit_disabled, -> { where(include_page_change_audit: false) }
  scope :page_change_audit_enabled, -> { where(include_page_change_audit: true) }
  scope :pending_page_change_audit, -> { page_change_audit_enabled.where(page_change_audit_completed_at: nil) }
  scope :completed_page_change_audit, -> { page_change_audit_enabled.where.not(page_change_audit_completed_at: nil) }

  def try_completion!
    if seconds_to_complete.nil? && completed?
      completed!
      true
    else
      false
    end
  end

  def completed!
    update_column(:seconds_to_complete, Time.now - created_at)
    make_primary! unless performance_audit_failed? || performance_audit_disabled?
    send_audit_completed_notifications_if_necessary
  end

  def performance_audit_completed!(tagsafe_score_confidence_range)
    unless performance_audit_failed?
      update(num_performance_audit_sets_ran: delta_performance_audits.count)
      PerformanceAuditManager::AveragePerformanceAuditsCreator.new(self).create_average_performance_audits!
      PerformanceAuditManager::MedianPerformanceAuditsCreator.new(self).find_and_apply_median_audits!
    end
    update(performance_audit_completed_at: Time.now, tagsafe_score_confidence_range: tagsafe_score_confidence_range)
    update_performance_audit_details_view(audit: self, now: true)
    purge_non_median_performance_audit_recordings!
    return if reload.try_completion!
    update_audit_table_row(audit: self, now: true)
    update_tag_version_table_row(tag_version: tag_version, now: true)
    update_tag_table_row(tag: tag, now: true)
  end

  def functional_tests_completed!
    update(functional_tests_completed_at: Time.now)
    return if reload.try_completion!
    update_audit_table_row(audit: self, now: true)
    update_tag_version_table_row(tag_version: tag_version, now: true)
    update_tag_table_row(tag: tag, now: true)
  end

  def page_change_audit_completed!
    update(page_change_audit_completed_at: Time.now)
    reload.try_completion!
  end

  def performance_audit_error!(msg)
    update!(performance_audit_error_message: msg)
    performance_audit_completed!(nil)
  end

  def make_primary!
    raise AuditError::InvalidPrimary, "audit is in a #{state} state, must be completed." unless completed?
    primary_audit_from_before = tag_version.primary_audit
    primary_audit_from_before.update!(primary: false) unless primary_audit_from_before.nil?
    update!(primary: true)
    after_became_primary(true)
  end

  def after_became_primary(update_views_now = false)
    # update_primary_audit_pill_for_tag_version(tag_version: tag_version, now: update_views_now)
    update_tag_table_row(tag: tag, now: update_views_now)
    update_tag_version_table_row(tag_version: tag_version, now: update_views_now)
    update_tag_current_stats(tag: tag, now: update_views_now)
    re_render_audit_table(tag_version: tag_version, now: update_views_now)
    re_render_tags_chart(domain: tag.domain, now: update_views_now)
    re_render_tag_chart(tag: tag, now: update_views_now)
    # update performance chart?...
  end

  def send_audit_completed_notifications_if_necessary
    unless initiated_by_domain_user.nil?
      initiated_by_domain_user.user.broadcast_notification(
        timestamp: Time.now.strftime("%m/%d/%y @ %l:%M %P %Z"),
        image: self.tag.try_image_url,
        partial: 'audits/completed_notification',
        partial_locals: { audit: self }
      )
    end
    if execution_reason != ExecutionReason.INITIAL_AUDIT
      NotificationModerator::AuditNotifier.new(self).notify!
    end
  end

  def enqueue_configured_audit_types
    AuditRunnerJobs::RunPerformanceAudit.perform_later(self) if include_performance_audit
    # PerformanceAuditManager::QueueMaintainer.new(audit).run_next_set_of_performance_audits_or_mark_as_completed include_performance_audit
    AuditRunnerJobs::RunPageChangeAudit.perform_later(self) if include_page_change_audit
    AuditRunnerJobs::RunFunctionalTestSuiteForAudit.perform_later(self) if include_functional_tests
  end

  ############
  ## STATES ##
  ############

  def state
    pending? ? 'pending' :
      performance_audit_failed? ? 'failed' : 'complete'
  end

  def completed?
    (!include_performance_audit || performance_audit_completed?) && 
      (!include_functional_tests || functional_tests_completed?) && 
      (!include_page_change_audit || page_change_audit_completed?)
  end

  def pending?
    !completed?
  end

  def performance_audit_completed?
    include_performance_audit && !performance_audit_completed_at.nil?
  end

  def performance_audit_pending?
    include_performance_audit && !performance_audit_completed?
  end

  def all_individual_performance_audits_completed?
    num_individual_performance_audits_remaining == 0
  end

  def functional_tests_completed?
    include_functional_tests && !functional_tests_completed_at.nil?
    # test_runs_with_tag.not_retries.completed.count == num_functional_tests_to_run && 
    #   test_runs_with_tag.not_retries.failed.count == test_runs_without_tag.not_retries.completed.count
  end

  def functional_tests_pending?
    include_functional_tests && !functional_tests_completed?
  end

  def page_change_audit_completed?
    include_page_change_audit && !page_change_audit_completed_at.nil?
  end

  def page_change_audit_pending?
    include_page_change_audit && !page_change_audit_completed?
  end

  def successful?
    !performance_audit_failed? && completed?
  end

  def performance_audit_failed?
    !performance_audit_error_message.nil?
  end

  def performance_audit_disabled?
    !include_performance_audit
  end

  def primary?
    primary
  end
  alias is_primary? primary?

  ########################
  ## PERFORMANCE AUDITS ##
  ########################

  def preferred_delta_performance_audit
    average_delta_performance_audit
  end

  def confidence_calculator
    PerformanceAuditManager::ConfidenceCalculator.new(self)
  end

  def purge_non_median_performance_audit_recordings!
    return if Util.env_is_true('DONT_PURGE_NON_MEDIAN_PERFORMANCE_AUDIT_RECORDINGS')
    performance_audits.where(type: [IndividualPerformanceAuditWithoutTag.to_s, IndividualPerformanceAuditWithTag.to_s]).each{ |perf_audit| perf_audit.puppeteer_recording&.purge_from_s3 }
  end

  def previous_primary_audit(disable_cache = false)
    return @previous_primary_audit if @previous_primary_audit && !disable_cache
    @previous_primary_audit = tag.audits.joins(:tag_version).primary.where('tag_versions.created_at < ?', tag_version.created_at).limit(1).first
  end

  def num_individual_performance_audits_remaining
    return 0 if performance_audit_completed?
    performance_audit_configuration.num_performance_audits_to_run * 2 - individual_performance_audits.completed_successfully.count
  end

  def num_individual_performance_audits_with_tag_remaining
    return 0 if performance_audit_completed?
    performance_audit_configuration.num_performance_audits_to_run - individual_performance_audits_with_tag.completed_successfully.count
  end

  def num_individual_performance_audits_without_tag_remaining
    return 0 if performance_audit_completed?
    performance_audit_configuration.num_performance_audits_to_run - individual_performance_audits_without_tag.completed_successfully.count
  end

  def individual_performance_audit_percent_complete
    return 100 if performance_audit_completed?
    if performance_audit_configuration.completion_indicator_type == PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE
      points_away_from_reaching_confidence = confidence_calculator.tagsafe_score_confidence_plus_minus - performance_audit_configuration.required_tagsafe_score_range
      100 - (points_away_from_reaching_confidence * 10)
    else
      (delta_performance_audits.count / performance_audit_configuration.num_performance_audits_to_run)*100
    end
  end

  def reached_maximum_failed_performance_audits?
    individual_performance_audits.failed.count >= maximum_individual_performance_audit_attempts
  end

  def maximum_individual_performance_audit_attempts
    Flag.flag_value_for_objects(tag, tag.domain, slug: 'max_individual_performance_audit_retries').to_i
  end

  ######################
  ## FUNCTIONAL TESTS ##
  ######################

  def has_functional_tests?
    tag.functional_tests.any?
  end

  def num_functional_tests_to_run_remaining
    num_functional_tests_to_run_including_without_tag_validation_runs - (test_runs_with_tag.not_retries.completed.count + test_runs_with_tag.not_retries.failed.count)
  end

  def num_inconclusive_functional_tests
    test_runs_with_tag.inconclusive.count
  end

  def completed_all_functional_tests?
    num_functional_tests_to_run_remaining.zero?
  end

  def passed_all_functional_tests?
    test_runs_with_tag.not_retries.passed.count + num_inconclusive_functional_tests == num_functional_tests_to_run
  end

  def display_functional_test_results
    "#{test_runs_with_tag.not_retries.passed.count} / #{num_functional_tests_to_run - test_runs_with_tag.not_retries.inconclusive.count}"
  end

  def num_functional_tests_to_run_including_without_tag_validation_runs
    num_functional_tests_to_run + test_runs_with_tag.failed.not_retries.count
  end

  def functional_tests_percent_complete
    total_num_tests_completed = test_runs_with_tag.passed.not_retries.count + 
                                  test_runs_with_tag.failed.not_retries.count + 
                                  test_runs_without_tag.completed.not_retries.count 
    (total_num_tests_completed.to_f / num_functional_tests_to_run_including_without_tag_validation_runs.to_f)*100.0
  end

  private

  def has_at_least_one_type_of_audit_enabled
    if !include_functional_tests && !include_page_change_audit && !include_performance_audit
      errors.add(:base, "An audit must have either performance audits, functional tests, or page change audits enabled.")
    end
  end
end