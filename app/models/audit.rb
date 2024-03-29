class Audit < ApplicationRecord
  class FailedExecution < StandardError; end;
  uid_prefix 'aud'

  RUNNABLE_AUDIT_COMPONENTS = [
    [MainThreadExecutionAuditComponent, 0.8], 
    [JsUsageAuditComponent, 0.1], 
    [JsFileSizeAuditComponent, 0.1]
  ]

  belongs_to :container, optional: false
  belongs_to :tag, optional: false
  belongs_to :tag_version, optional: true
  belongs_to :page_url, optional: false
  belongs_to :initiated_by_container_user, class_name: ContainerUser.to_s, optional: true
  belongs_to :execution_reason, optional: false

  has_many :audit_components, dependent: :destroy
  has_one :main_thread_execution_audit_component
  has_one :js_file_size_audit_component
  has_one :js_usage_audit_component
  accepts_nested_attributes_for :audit_components

  before_create { self.started_at = Time.current }
  after_create_commit :prepend_audit_row_to_tag_details_page

  scope :completed, -> { where.not(completed_at: nil) }
  scope :successful, -> { completed.where(error_message: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :pending, -> { where(completed_at: nil) }

  scope :by_page_url, -> (page_url) { where(page_url: page_url) }
  scope :by_execution_reason, -> (execution_reason) { where(execution_reason: execution_reason) }

  validate :has_valid_audit_components
  validate :only_one_new_release_audit_per_tag_version
  validate :manual_executions_has_initiated_by_user
  validate :tag_version_belongs_to_tag
  validates :tagsafe_score, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0 }, if: :successful?

  def self.run!(tag:, tag_version:, page_url:, execution_reason:, initiated_by_container_user: nil)
    audit = Audit.run(
      tag: tag,
      tag_version: tag_version,
      page_url: page_url,
      execution_reason: execution_reason,
      initiated_by_container_user: initiated_by_container_user,
    )
    raise FailedExecution.new(audit.errors.full_messages.join(', ')) if audit.errors.any?
    audit
  end

def self.run(tag:, tag_version:, page_url:, execution_reason:, initiated_by_container_user: nil)
    components_to_run = RUNNABLE_AUDIT_COMPONENTS.map{ |klass, weight| { type: klass.to_s, score_weight: weight }}
    Audit.create(
      container: page_url.container,
      tag: tag,
      tag_version: tag_version,
      page_url: page_url,
      execution_reason: execution_reason,
      initiated_by_container_user: initiated_by_container_user,
      audit_components_attributes: components_to_run
    )
  end

  def retry
    raise "Cannot retry an audit that did not fail." unless failed?
    Audit.run!(
      tag: tag,
      tag_version: tag_version,
      page_url: page_url,
      execution_reason: execution_reason,
      initiated_by_container_user: initiated_by_container_user
    )
  end

  def completed!
    raise "Audit is already marked as completed." if completed?
    self.tagsafe_score = calculate_tagsafe_score!
    self.completed_at = Time.current
    self.save!

    update_tag_details_audit_row
    update_audit_breakdown_view
    broadcast_audit_completed_notification
    
    tag.update!(primary_audit: self) if successful? && (!tag_version.present? || tag_version.is_tags_current_live_tag_version? || tag.primary_audit.nil?)
    
    if successful? && tag_version.present? && tag_version.primary_audit.nil?
      tag_version.update!(primary_audit: self)
      # LiveTagVersionPromoter.new(tag_version).set_as_tags_live_version_if_criteria_is_met! if tag.is_tagsafe_hosted
    end
  end

  def calculate_tagsafe_score!
    raise "Cannot calculate score, not all AuditComponents have completed" unless all_components_completed?
    audit_components.sum(&:weighted_score_for_audit)
  end

  def poor_scoring_audit_components
    audit_components.where('score < 80')
  end

  def failed!(err_msg)
    update!(error_message: err_msg, completed_at: Time.current)
    update_tag_details_audit_row
  end

  def successful?
    completed? && !failed?
  end

  def completed?
    !pending?
  end

  def pending?
    completed_at.nil?
  end

  def failed?
    error_message.present?
  end
  
  def after_audit_component_completed(audit_component)
    completed! if all_components_completed?
  end

  def after_audit_component_failed(audit_component)
    failed!(audit_component.error_message)
  end

  def all_components_completed?
    audit_components.completed.count == audit_components.count
  end

  def audit_to_compare_with
    if tag_version && tag_version.previous_version
      tag_version.previous_version.primary_audit
    else
      tag.audits.successful.by_page_url(page_url).most_recent_first.older_than(created_at).limit(1).first
    end
  end

  def formatted_tagsafe_score
    return if tagsafe_score.nil?
    tagsafe_score.round(2)
  end

  private

  def broadcast_audit_completed_notification
    if execution_reason.new_release?
      container.container_users.each do |container_user|
        container_user.user.broadcast_notification(
          title: "Audit completed",
          message: "Audit completed for #{tag.tag_snippet.name} with a Tagsafe Score of #{formatted_tagsafe_score}.",
          cta_url: "/containers/#{container.uid}/tag_snippets/#{tag.tag_snippet.uid}/tags/#{tag.uid}/audits/#{uid}",
          cta_text: "View audit",
          image: tag.try_image_url,
        )
      end
    elsif execution_reason.manual?
      initiated_by_container_user.user.broadcast_notification(
          title: "Audit completed",
          message: "Audit completed for #{tag.tag_snippet.name} with a Tagsafe Score of #{formatted_tagsafe_score}.",
          cta_url: "/containers/#{container.uid}/tag_snippets/#{tag.tag_snippet.uid}/tags/#{tag.uid}/audits/#{uid}",
          cta_text: "View audit",
          image: tag.try_image_url,
      )
    end
  end

  def update_tag_details_audit_row
    # broadcast_replace_to(
    #   "tag_#{tag.uid}_details_view_stream", 
    #   target: "audit_#{uid}_row",
    #   partial: 'audits/audit_row',
    #   locals: { audit: self, include_tag_name: false }
    # )
  end

  def update_audit_breakdown_view
    # broadcast_replace_to(
    #   "audit_#{uid}_breakdown_view_stream",
    #   target: "audit_#{uid}_breakdown",
    #   partial: 'audits/breakdown',
    #   locals: { audit: self }
    # )
  end

  def prepend_audit_row_to_tag_details_page
    # broadcast_prepend_to(
    #   "tag_#{tag.uid}_details_view_stream", 
    #   target: "tag_#{tag.uid}_audits_table_rows",
    #   partial: 'audits/audit_row',
    #   locals: { audit: self, include_tag_name: false }
    # )
  end

  def tag_version_belongs_to_tag
    if tag_version.present? && tag_version.tag != tag
      errors.add(:tag_version, "Tag Version #{tag_version.uid} does not belong to Tag #{tag.uid}")
    end
  end

  def has_valid_audit_components
    if audit_components.none?
      errors.add(:base, "Cannot create an Audit without any Audit Components.")
    end
    if audit_components.sum(&:score_weight) != 1.0
      errors.add(:base, "Audit Components score_weight adds up to #{audit_components.sum(:score_weight)}. They must add up to 1.0")
    end
  end

  def only_one_new_release_audit_per_tag_version
    return if tag_version.nil? || !execution_reason.new_release?
    if tag_version.audits.successful.where(execution_reason: ExecutionReason.NEW_RELEASE, page_url: page_url).where.not(id: id).any?
      errors.add(:base, "Tag Version #{tag_version.uid} already has an Audit with an Execution Reason of `New Release` for #{page_url.friendly_url}.")
    end
  end

  def manual_executions_has_initiated_by_user
    if execution_reason.manual? && !initiated_by_container_user.present?
      errors.add(:base, "Must specify the `initiated_by_container_user` for manually executed Audits.")
    end
  end
end