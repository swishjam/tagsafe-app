class Audit < ApplicationRecord
  include Streamable
  uid_prefix 'aud'
  acts_as_paranoid

  belongs_to :tag_version
  belongs_to :tag
  belongs_to :execution_reason
  belongs_to :page_url
  belongs_to :performance_audit_calculator

  has_one :performance_audit_configuration
  accepts_nested_attributes_for :performance_audit_configuration
  has_many :performance_audits, dependent: :destroy
  # has_many :blocked_resources, through: :performance_audits
  has_one :delta_performance_audit, class_name: 'DeltaPerformanceAudit', dependent: :destroy
  has_many :individual_performance_audits_with_tag, class_name: 'IndividualPerformanceAuditWithTag',  dependent: :destroy
  has_many :individual_performance_audits_without_tag, class_name: 'IndividualPerformanceAuditWithoutTag',  dependent: :destroy

  has_many :test_runs, dependent: :destroy
  has_many :test_runs_with_tag, class_name: 'TestRunWithTag', dependent: :destroy
  has_many :test_runs_without_tag, class_name: 'TestRunWithoutTag', dependent: :destroy

  has_one :page_change_audit, class_name: 'PageChangeAudit', dependent: :destroy

  #############
  # CALLBACKS #
  #############

  after_create_commit -> { prepend_audit_to_list(audit: self, now: true) }

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
    update_column(:seconds_to_complete, Time.now - enqueued_suite_at)
    make_primary! unless performance_audit_failed?
    AuditCompletedJob.perform_later(self)
  end

  def performance_audit_completed!
    create_delta_performance_audit! unless performance_audit_failed? || !delta_performance_audit.nil?
    update(performance_audit_completed_at: Time.now)
    update_performance_audit_details_view(audit: self, now: true)
    return if reload.try_completion!
    # performance_audit_completed? returns false without a reload..
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
    performance_audit_completed!
  end

  def performance_audit_with_tag_used_for_scoring
    individual_performance_audits_with_tag.where(used_for_scoring: true).limit(1).first
  end

  def performance_audit_without_tag_used_for_scoring
    individual_performance_audits_without_tag.where(used_for_scoring: true).limit(1).first
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
    re_render_audit_table(audit: self, now: update_views_now)
    re_render_tags_chart(domain: tag.domain, now: update_views_now)
    re_render_tag_chart(tag: tag, now: update_views_now)
    # update performance chart?...
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

  def primary?
    primary
  end
  alias is_primary? primary?

  ########################
  ## PERFORMANCE AUDITS ##
  ########################

  def create_delta_performance_audit!
    raise StandardError, "Audit #{id} already has a DeltaPerformanceAudit" unless delta_performance_audit.nil?
    PerformanceAuditManager::DeltaPerformanceAuditCreator.new(self).create_delta_audit!
  end

  def enqueue_next_individual_performance_audit_if_necessary!(audit_type, options = {})
    num_remaining_audits_for_type = audit_type == :with_tag ? num_individual_performance_audits_with_tag_remaining : num_individual_performance_audits_without_tag_remaining
    if num_remaining_audits_for_type.zero?
      Rails.logger.info "Audit #{id} completed performance audits for #{audit_type}"
      if num_individual_performance_audits_remaining.zero?
        Rails.logger.info "All performance audits are completed!"
        performance_audit_completed!
      else
        Rails.logger.info "Still has #{num_individual_performance_audits_remaining} to complete, letting other audit_type handle it."
      end
    elsif individual_performance_audits.failed.count < maximum_individual_performance_audit_attempts
      Rails.logger.info "Enqueuing next #{audit_type} performance audit for Audit #{id}, #{num_remaining_audits_for_type} remaining to complete."
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(type: audit_type, audit: self, tag_version: tag_version, options: options)
    else
      Rails.logger.info "Reached maximum performance audit retry count of #{maximum_individual_performance_audit_attempts}, stopping audit."
      performance_audit_error!("Reached maximum performance audit retry count of #{maximum_individual_performance_audit_attempts}, stopping audit.")
    end
  end

  def previous_primary_audit(force = false)
    return @previous_primary_audit if @previous_primary_audit && !force
    @previous_primary_audit = tag.audits.joins(:tag_version).primary.where('tag_versions.created_at < ?', tag_version.created_at).limit(1).first
  end

  def individual_performance_audits
    performance_audits.where(type: %w[IndividualPerformanceAuditWithTag IndividualPerformanceAuditWithoutTag])
    # individual_performance_audits_with_tag + individual_performance_audits_without_tag
  end

  def num_individual_performance_audits_remaining
    performance_audit_configuration.performance_audit_iterations * 2 - individual_performance_audits.completed_successfully.count
  end

  def num_individual_performance_audits_with_tag_remaining
    performance_audit_configuration.performance_audit_iterations - individual_performance_audits_with_tag.completed_successfully.count
  end

  def num_individual_performance_audits_without_tag_remaining
    performance_audit_configuration.performance_audit_iterations - individual_performance_audits_without_tag.completed_successfully.count
  end

  def individual_performance_audit_percent_complete
    ((individual_performance_audits.completed_successfully.count) / (performance_audit_configuration.performance_audit_iterations * 2.0))*100
  end

  def maximum_individual_performance_audit_attempts
    Flag.flag_value_for_objects(tag, tag.domain, tag.domain.organization, slug: 'max_individual_performance_audit_retries').to_i
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
end