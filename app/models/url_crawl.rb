class UrlCrawl < ApplicationRecord
  belongs_to :domain
  has_many :found_tags, class_name: 'Tag'

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :successful, -> { completed.where(error_message: nil ) }

  after_create_commit { broadcast_replace_later_to "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain }}
  after_update_commit { broadcast_replace_later_to "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain }}

  def self.most_recent
    most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def found_tag!(
    tag_url,
    monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', 
    should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', 
    is_allowed_third_party_tag: false, 
    is_third_party_tag: true,
    initial_crawl: false,
    should_log_tag_checks: true,
    consider_query_param_changes_new_tag: false,
    page_url_to_perform_audit_on: url,
    performance_audit_iterations: (ENV['DEFAULT_performance_audit_iterations'] || '5').to_i
  )
    parsed_url = URI.parse(tag_url)
    tag = found_tags.create!(
      domain: domain,
      full_url: tag_url,
      url_domain: parsed_url.host,
      url_path: parsed_url.path,
      url_query_param: parsed_url.query,
      tag_preferences_attributes: {
        monitor_changes: monitor_changes,
        is_allowed_third_party_tag: is_allowed_third_party_tag,
        is_third_party_tag: is_third_party_tag,
        should_run_audit: should_run_audit,
        should_log_tag_checks: should_log_tag_checks,
        consider_query_param_changes_new_tag: consider_query_param_changes_new_tag,
        page_url_to_perform_audit_on: url,
        performance_audit_iterations: performance_audit_iterations
      }
    )
    # if it's the first time scanning the domain for tags, don't run the job
    # we may eventually move this into the job itself, but for now let's just not bother enqueuing
    AfterTagCreationJob.perform_later(tag) unless initial_crawl
    tag
  end

  def pending?
    completed_at.nil?
  end

  def completed?
    !pending?
  end

  def failed?
    !error_message.nil?
  end

  def successful?
    !failed? && completed?
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
  end

  def errored!(error_msg)
    update(error_message: error_msg)
    completed!
  end
end