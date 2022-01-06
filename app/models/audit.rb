class Audit < ApplicationRecord
  include Streamable
  uid_prefix 'aud'
  acts_as_paranoid

  belongs_to :tag_version
  belongs_to :tag
  belongs_to :execution_reason
  belongs_to :page_url
  belongs_to :performance_audit_calculator

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
  # after_create_commit -> { update_primary_audit_pill_for_tag_version(tag_version: tag_version, now: true) }

  ##########
  # SCOPES #
  ##########

  scope :primary, -> { where(primary: true) }
  scope :not_primary, -> { where(primary: false) }

  scope :pending_performance_audit, -> { where(seconds_to_complete: nil) }
  scope :completed_performance_audit, -> { where.not(seconds_to_complete: nil) }
  scope :failed_performance_audit, -> { where.not(error_message: nil) }
  scope :successful_performance_audit, -> { completed.where(error_message: nil) }

  scope :pending, -> { pending_performance_audit }
  scope :completed, -> { completed_performance_audit }
  scope :failed, -> { failed_performance_audit }
  scope :successful, -> { successful_performance_audit }

  scope :throttled, -> { where(throttled: true) }
  scope :not_throttled, -> { where(throttled: false) }

  def try_completion!
    if !completed? && 
        (!include_page_change_audit || page_change_audit_completed?) && 
        (!include_functional_tests || functional_tests_completed?) && 
        (!include_performance_audit || performance_audit_completed?)
      completed!
      true
    else
      false
    end
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
    make_primary! unless failed?
    AuditCompletedJob.perform_later(self)
  end

  def performance_audit_completed!
    create_delta_performance_audit!
    # performance_audit_completed? returns false without a reload..
    unless reload.try_completion!
      update_audit_details_view(audit: self, now: true)
      update_audit_table_row(audit: self, now: true)
      update_tag_version_table_row(tag_version: tag_version, now: true)
      update_tag_table_row(tag: tag, now: true)
    end
  end

  def functional_tests_completed!
    unless reload.try_completion!
      update_audit_table_row(audit: self, now: true)
      update_tag_version_table_row(tag_version: tag_version, now: true)
      update_tag_table_row(tag: tag, now: true)
    end
  end

  def page_change_audit_completed!
    reload.try_completion!
  end

  def error!(msg)
    update!(error_message: msg)
    completed!
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
    # update performance chart...
  end

  ############
  ## STATES ##
  ############

  def state
    pending? ? 'pending' :
      failed? ? 'failed' : 'complete'
  end

  def completed?
    !completed_at.nil?
  end

  def performance_audit_completed?
    !!delta_performance_audit&.completed?
  end

  def all_individual_performance_audits_completed?
    individual_performance_audits_remaining == 0
  end

  def performance_audit_pending?
    include_performance_audit && !delta_performance_audit&.completed?
  end

  def functional_tests_completed?
    test_runs_with_tag.not_retries.completed.count == num_functional_tests_to_run && 
      test_runs_with_tag.not_retries.failed.count == test_runs_without_tag.not_retries.completed.count
  end

  def functional_tests_pending?
    include_functional_tests && !functional_tests_completed?
  end

  def page_change_audit_completed?
    !!page_change_audit&.completed?
  end

  def page_change_audit_pending?
    include_page_change_audit && !page_change_audit_completed?
  end

  def successful?
    !failed? && completed?
  end

  def failed?
    !error_message.nil?
  end

  def pending?
    !completed?
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

  def previous_primary_audit(force = false)
    return @previous_primary_audit if @previous_primary_audit && !force
    @previous_primary_audit = tag.audits.joins(:tag_version).primary.where('tag_versions.created_at < ?', tag_version.created_at).limit(1).first
  end

  def individual_performance_audits
    performance_audits.where(type: %w[IndividualPerformanceAuditWithTag IndividualPerformanceAuditWithoutTag])
    # individual_performance_audits_with_tag + individual_performance_audits_without_tag
  end

  def individual_performance_audits_remaining
    performance_audit_iterations * 2 - individual_performance_audits.completed_successfully.count
  end

  def individual_performance_audit_percent_complete
    ((individual_performance_audits.completed_successfully.count) / (performance_audit_iterations * 2.0))*100
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

  def passed_all_functional_tests?
    test_runs_with_tag.not_retries.passed.count == num_functional_tests_to_run
  end

  def display_functional_test_results
    "#{test_runs_with_tag.not_retries.passed.count} / #{num_functional_tests_to_run}"
  end
end