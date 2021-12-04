class Audit < ApplicationRecord
  uid_prefix 'aud'
  acts_as_paranoid

  belongs_to :tag_version
  belongs_to :tag
  belongs_to :execution_reason
  belongs_to :audited_url, class_name: 'UrlToAudit'
  belongs_to :performance_audit_calculator

  has_many :performance_audits, dependent: :destroy
  has_many :blocked_resources, through: :performance_audits
  has_one :delta_performance_audit, class_name: 'DeltaPerformanceAudit', dependent: :destroy
  has_many :individual_performance_audits_with_tag, class_name: 'IndividualPerformanceAuditWithTag',  dependent: :destroy
  has_many :individual_performance_audits_without_tag, class_name: 'IndividualPerformanceAuditWithoutTag',  dependent: :destroy

  #############
  # CALLBACKS #
  #############

  after_create_commit -> { prepend_audit_to_list(now: true) }
  after_create_commit -> { tag_version.update_primary_audit_pill(now: true) }

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

  def state
    pending? ? 'pending' :
      failed? ? 'failed' : 'complete'
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
    make_primary! unless failed?
    update_audit_details_view
    AuditCompletedJob.perform_later(self)
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

  def completed?
    !completed_at.nil?
  end

  def create_delta_performance_audit!
    raise StandardError, "Audit #{id} already has a DeltaPerformanceAudit" unless delta_performance_audit.nil?
    PerformanceAuditManager::DeltaPerformanceAuditCreator.new(self).create_delta_audit!
  end

  def successful?
    !failed? && completed?
  end

  def failed?
    !error_message.nil?
  end

  def pending?
    completed_at.nil?
  end

  def completed?
    !pending?
  end

  def primary?
    primary
  end
  alias is_primary? primary?

  def make_primary!
    raise AuditError::InvalidPrimary, "audit is in a #{state} state, must be completed." unless completed?
    primary_audit_from_before = tag_version.primary_audit
    # THE ORDER OF THESE UPDATES MATTER DUE TO `check_for_new_primary_audit`
    primary_audit_from_before.update!(primary: false) unless primary_audit_from_before.nil?
    update!(primary: true)
    after_became_primary(true)
  end

  def after_became_primary(update_views_now = false)
    tag_version.update_primary_audit_pill(now: update_views_now)
    tag_version.update_tag_version_table_row(now: update_views_now)
    re_render_audit_table(now: update_views_now)
    tag.domain.re_render_tags_chart(now: update_views_now)
    tag.re_render_chart(now: update_views_now)
    # update performance chart...
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

  def all_individual_performance_audits_completed?
    individual_performance_audits_remaining == 0
  end

  def individual_performance_audit_percent_complete
    ((individual_performance_audits.completed_successfully.count) / (performance_audit_iterations * 2.0))*100
  end

  def should_show_page_load_resources?
    completed? && !failed? && blocked_resources.any?
  end

  def maximum_individual_performance_audit_attempts
    Flag.flag_value_for_objects(tag, tag.domain, tag.domain.organization, slug: 'max_individual_performance_audit_retries').to_i
  end

  ###################
  ## TURBO STREAMS ##
  ###################

  def prepend_audit_to_list(now: false)
    broadcast_method = now ? :broadcast_prepend_to : :broadcast_prepend_later_to
    send(broadcast_method,
      "tag_version_#{tag_version.uid}_audits_view_stream", 
      target: "tag_version_#{tag_version.uid}_audits_table_rows",
      partial: 'audits/audit_row',
      locals: { audit: self, streamed: true }
    )
  end

  def update_audit_details_view(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method,
      "audit_#{uid}_details_view_stream",
      target: "audit_#{uid}",
      partial: 'audits/show',
      locals: { audit: self, previous_audit: tag_version.previous_version&.primary_audit, tag: tag, tag_version: tag_version, streamed: true }
    )
  end

  def update_audit_table_row(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method,
      "tag_version_#{tag_version.uid}_audits_view_stream", 
      target: "audit_#{uid}_row",
      partial: 'audits/audit_row',
      locals: { audit: self, streamed: true }
    )
  end

  def re_render_audit_table(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    updated_audits_collection = tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
    send(broadcast_method,
      "tag_version_#{tag_version.uid}_audits_view_stream",
      target: "tag_version_#{tag_version.uid}_audits_table",
      partial: 'audits/audits_table',
      locals: { tag_version: tag_version, audits: updated_audits_collection, streamed: true }
    )
  end

  def update_completion_indicators
    return unless ENV['INCLUDE_AUDIT_COMPLETION_INDICATOR'] == 'true'
    broadcast_replace_to "#{id}_completion_indicator", 
                          target: "#{id}_completion_indicator", 
                          partial: 'audits/completion_indicator', 
                          locals: { audit: self }
  end
end