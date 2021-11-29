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
  has_one :delta_performance_audit, dependent: :destroy
  has_many :individual_performance_audits_with_tag, class_name: 'IndividualPerformanceAuditWithTag',  dependent: :destroy
  has_many :individual_performance_audits_without_tag, class_name: 'IndividualPerformanceAuditWithoutTag',  dependent: :destroy

  #############
  # CALLBACKS #
  #############

  # column_update_listener :primary
  after_create_commit { broadcast_prepend_to "#{tag_version_id}_tag_version_audits", target: "#{tag_version_id}_tag_version_audits" }
  after_update_commit :update_audit_content
  # after_update_commit { tag.update_tag_content }
  # after_primary_updated_to true, -> { tag_version.update_tag_version_content }
  after_update_commit :check_for_new_primary_audit

  ##########
  # SCOPES #
  ##########
  scope :primary, -> { where(primary: true) }

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

  def error!(msg)
    Rails.logger.info msg
    Resque.logger.info msg
    update!(error_message: msg)
    completed!
  end

  # to prepare for when we have multiple types of audits, not just performance audits...
  def delta_performance_audit_completed!
    completed!
    check_after_completion
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

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
  end

  def create_delta_performance_audit!
    raise StandardError, "Audit #{id} already has a DeltaPerformanceAudit" unless delta_performance_audit.nil?
    PerformanceAuditManager::DeltaPerformanceAuditCreator.new(self).create_delta_audit!
  end

  def check_after_completion
    if completed?
      make_primary! unless primary? || failed?
      AuditCompletedJob.perform_later(self) unless execution_reason == ExecutionReason.INITIAL_AUDIT
    end
  end

  # def dequeue_pending_performance_audits!
  #   dequeues = Resque::Job.destroy(:performance_audit_runner_queue, RunIndividualPerformanceAuditJob, {"_aj_globalid"=>"gid://tag-safe/Audit/#{id}"}, {"_aj_globalid"=>"gid://tag-safe/TagVersion/#{tag_version_id}"}, {"_aj_serialized"=>"ActiveJob::Serializers::SymbolSerializer", "value"=>"without_tag"})
  #   dequeues += Resque::Job.destroy(:performance_audit_runner_queue, RunIndividualPerformanceAuditJob, {"_aj_globalid"=>"gid://tag-safe/Audit/#{id}"}, {"_aj_globalid"=>"gid://tag-safe/TagVersion/#{tag_version_id}"}, {"_aj_serialized"=>"ActiveJob::Serializers::SymbolSerializer", "value"=>"with_tag"})
  #   dequeues
  # end

  # def attempt_retry
  #   if ENV['AUDIT_ATTEMPT_NUMBER'] && attempt_number <= ENV['AUDIT_ATTEMPT_NUMBER'].to_i
  #     Rails.logger.info "Retrying audit for tag #{tag.id}. Will be the #{attempt_number+1} attempt."
  #     retry!
  #   else
  #     Rails.logger.error "Reached max number of audit retry attempts: #{attempt_number}. Stopping retries."
  #   end
  # end

  def retry!
    tag_version.perform_audit_now(audit.audited_url, ExecutionReason.RETRY)
  end

  def update_audit_content
    broadcast_replace_to "#{tag_version_id}_tag_version_audits"
    if completed?
      broadcast_replace_to self, partial: 'audits/show', locals: { tag: tag, tag_version: tag_version, audit: self, previous_audit: tag_version.previous_version&.primary_audit }
    end
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
    raise AuditError::InvalidPrimary if failed? || pending?
    primary_audit_from_before = tag_version.primary_audit
    primary_audit_from_before.update!(primary: false) unless primary_audit_from_before.nil?
    update!(primary: true)
  end

  def check_for_new_primary_audit
    if saved_changes['primary'] && saved_changes['primary'][1] == true
      tag.update_tag_content
      # update chart...
      # broadcast_replace_later_to 
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

  def update_completion_indicators
    return unless ENV['INCLUDE_AUDIT_COMPLETION_INDICATOR'] == 'true'
    broadcast_replace_to "#{id}_completion_indicator", 
                          target: "#{id}_completion_indicator", 
                          partial: 'audits/completion_indicator', 
                          locals: { audit: self }
  end
end