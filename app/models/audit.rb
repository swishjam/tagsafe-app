class Audit < ApplicationRecord
  include Streamable
  # TODO: PerformanceAuditCacheGenerator has no dedicated models
  # include HasExecutedStepFunction
  uid_prefix 'aud'

  belongs_to :initiated_by_domain_user, class_name: DomainUser.to_s, optional: true
  belongs_to :domain
  belongs_to :tag_version, optional: true
  belongs_to :tag
  belongs_to :execution_reason
  belongs_to :page_url
  belongs_to :performance_audit_calculator

  has_many :credit_wallet_transactions, as: :record_responsible_for_charge
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

  has_many :test_runs, dependent: :destroy
  has_many :test_runs_with_tag, class_name: TestRunWithTag.to_s
  has_many :test_runs_without_tag, class_name: TestRunWithoutTag.to_s

  has_one :page_change_audit, class_name: PageChangeAudit.to_s, dependent: :destroy

  ###############
  # VALIDATIONS #
  ###############

  validate :has_at_least_one_type_of_audit_enabled
  validate :can_afford?
  validate :has_valid_subscription?

  #############
  # CALLBACKS #
  #############

  after_create_commit -> { prepend_audit_to_list(audit: self, now: true) }
  after_create_commit :enqueue_configured_audit_types
  after_create_commit :broadcast_audit_began_notification_if_necessary
  after_create_commit :charge_domain_for_credits_used!
  after_create_commit { tag.touch(:last_audit_began_at) }

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
  scope :successful_performance_audit, -> { completed_performance_audit.where(performance_audit_error_message: nil) }
  scope :failed_performance_audit, -> { where.not(performance_audit_error_message: nil) }

  scope :functional_tests_disabled, -> { where(include_functional_tests: false) }
  scope :functional_tests_enabled, -> { where(include_functional_tests: true) }
  scope :pending_functional_tests, -> { functional_tests_enabled.where(functional_tests_completed_at: nil ) }
  scope :completed_functional_tests, -> { functional_tests_enabled.where.not(functional_tests_completed_at: nil ) }
  scope :at_least_one_functional_test_run, -> { includes(:test_runs).where.not(test_runs: { id: nil }) }

  scope :page_change_audit_disabled, -> { where(include_page_change_audit: false) }
  scope :page_change_audit_enabled, -> { where(include_page_change_audit: true) }
  scope :pending_page_change_audit, -> { page_change_audit_enabled.where(page_change_audit_completed_at: nil) }
  scope :completed_page_change_audit, -> { page_change_audit_enabled.where.not(page_change_audit_completed_at: nil) }

  scope :by_execution_reason, -> (execution_reason) { where(execution_reason: execution_reason) }
  scope :automated, -> { by_execution_reason(ExecutionReason.automated) }
  scope :billable, -> { successful_performance_audit }

  # scope :most_current, -> { where(is_most_current: true) }

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
    mark_as_most_current_if_possible
    send_audit_completed_notifications_if_necessary
    send_audit_completed_emails
    issue_credits_for_any_failures
    stream_updates_to_views(true)
  end

  def mark_as_most_current_if_possible
    return if performance_audit_failed? || performance_audit_pending?
    previous_most_current_audit = tag.most_current_audit
    should_be_considered_most_current = previous_most_current_audit.nil? ||
                                          tag_version.nil? || 
                                          tag_version.most_recent_version? || 
                                          previous_most_current_audit.tag_version.nil? || 
                                          previous_most_current_audit.tag_version.created_at < tag_version.created_at
    return unless should_be_considered_most_current
    tag.update!(most_current_audit: self)
  end

  def audit_to_compare_with
    tag.audits.completed_performance_audit.successful_performance_audit.most_recent_first.older_than(created_at).limit(1).first
  end

  def performance_audit_completed!(tagsafe_score_confidence_range)
    unless performance_audit_failed?
      PerformanceAuditManager::AveragePerformanceAuditsCreator.new(self).create_average_performance_audits!
      PerformanceAuditManager::MedianPerformanceAuditsCreator.new(self).find_and_apply_median_audits!
    end
    update(
      performance_audit_completed_at: Time.current,
      num_performance_audit_sets_ran: delta_performance_audits.count,
      tagsafe_score_confidence_range: tagsafe_score_confidence_range,
      tagsafe_score_is_confident: tagsafe_score_confidence_range && tagsafe_score_confidence_range <= performance_audit_configuration.required_tagsafe_score_range
    )
    update_performance_audit_details_view(audit: self, now: true)
    purge_non_median_performance_audit_recordings!
    return if reload.try_completion!
    update_audit_table_row(audit: self, now: true)
    # update_tag_version_table_row(tag_version: tag_version, now: true)
    update_tag_table_row(tag: tag, now: true)
  end

  def functional_tests_completed!
    update(functional_tests_completed_at: Time.now)
    return if reload.try_completion!
    update_audit_table_row(audit: self, now: true)
    # update_tag_version_table_row(tag_version: tag_version, now: true)
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

  # def make_primary!
  #   raise AuditError::InvalidPrimary, "audit is in a #{state} state, must be completed." unless completed?
  #   return unless tag.should_roll_up_audits_by_tag_version?
  #   primary_audit_from_before = tag_version.primary_audit
  #   primary_audit_from_before.update!(primary: false) unless primary_audit_from_before.nil?
  #   update!(primary: true)
  #   after_became_primary(true)
  # end

  def stream_updates_to_views(update_views_now = false)
    update_tag_table_row(tag: tag, now: update_views_now)
    update_tag_current_stats(tag: tag, now: update_views_now)
    re_render_audit_table(tag_version: tag_version, now: update_views_now)    
  end

  def send_audit_completed_emails
    # usage_emailer = SubscriptionUsageAnalyzer::UsageForMonth.new(domain)
    # usage_emailer.send_exceeded_usage_email_if_necessary
    # usage_emailer.send_usage_warning_email_if_necessary
  end

  def broadcast_audit_began_notification_if_necessary
    return unless execution_reason.tagsafe_provided?
    domain.users.each do |user|
      user.broadcast_notification(
        image: self.tag.try_image_url,
        partial: 'notifications/audits/tagsafe_provided_began',
        partial_locals: { audit: self }
      )
    end
  end

  def send_audit_completed_notifications_if_necessary
    if initiated_by_domain_user.present?
      initiated_by_domain_user.user.broadcast_notification(
        image: self.tag.try_image_url,
        partial: 'notifications/audits/completed',
        partial_locals: { audit: self }
      )
    elsif execution_reason.tagsafe_provided?
      domain.users.each do |user|
        user.broadcast_notification(
          image: self.tag.try_image_url,
          partial: 'notifications/audits/completed',
          partial_locals: { audit: self }
        )
      end
    end
  end

  def enqueue_configured_audit_types
    return if performance_audit_failed? # we need a better place to keep general audit errors....
    AuditRunnerJobs::RunPerformanceAudit.perform_later(self) if include_performance_audit
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

  def performance_audit_completed_successfully?
    performance_audit_completed? && !performance_audit_failed?
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

  def initiated_by_user?
    initiated_by_domain_user_id.present?
  end

  def run_on_live_tag?
    tag_version.nil?
  end
  alias ran_on_live_tag? run_on_live_tag?

  def run_on_tagsafe_tag_version?
    tag_version.present?
  end
  alias ran_on_tagsafe_tag_version? run_on_tagsafe_tag_version?

  ########################
  ## PERFORMANCE AUDITS ##
  ########################

  def tagsafe_score
    preferred_delta_performance_audit.tagsafe_score
  end

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
    individual_performance_audits.failed.count >= performance_audit_configuration.max_failures
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

  def issue_credits_for_any_failures
    return unless performance_audit_failed? || domain.credit_wallet_for_current_month_and_year.nil?
    performance_audit_price = PriceCalculators::Audits.new(self).cumulative_price_for_performance_audit
    domain.credit_wallet_for_current_month_and_year.credit!(performance_audit_price, record_responsible_for_credit: self, reason: CreditWalletTransaction::Reasons.FAILED_PERFORMANCE_AUDIT)
  end

  def charge_domain_for_credits_used!
    return if performance_audit_failed?
    price = PriceCalculators::Audits.new(self).price
    return if price.zero?
    domain.credit_wallet_for_current_month_and_year.debit!(price, record_responsible_for_debit: self, reason: CreditWalletTransaction::Reasons.AUDIT) unless price.zero?
  end

  def can_afford?
    price_for_audit = PriceCalculators::Audits.new(self).price
    return true if price_for_audit.zero?
    num_credits_in_wallet = domain.credit_wallet_for_current_month_and_year&.credits_remaining || Float::INFINITY
    return true if price_for_audit <= num_credits_in_wallet
    insufficient_credits_message = "Your account has insufficient credits to run this audit. This audit would cost #{price_for_audit} credits based on your configuration, but you only have #{num_credits_in_wallet} credits remaining this month."
    if execution_reason.manual?
      errors.add(:base, insufficient_credits_message)
    else
      self.performance_audit_error_message = insufficient_credits_message
    end
  end

  def has_valid_subscription?
    return true if domain.current_subscription_plan.nil? # edge case where an Audit is run before SusbcriptionPlan is selected
    return true unless domain.current_subscription_plan.delinquent? || domain.current_subscription_plan.canceled?
    invalid_subscription_message = "Your Tagsafe subscription is frozen due to inability to charge your payment method on file. Update your payment method in order to continue using Tagsafe to it's full extent."
    if execution_reason.manual?
      errors.add(:base, invalid_subscription_message)
    else
      self.performance_audit_error_message = invalid_subscription_message
    end
  end
end