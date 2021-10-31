class UrlCrawl < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :domain
  has_many :found_tags, class_name: 'Tag'
  alias tags_found found_tags

  # has_many :events, dependent: :destroy, class_name: 'TagSafeEvent'
  # has_many :tag_added_to_site_events, class_name: 'TagAddedToSiteEvent'
  # has_many :tag_removed_from_site_events, class_name: 'TagRemovedFromSiteEvent'
  # has_many :tag_url_query_param_change_events, class_name: 'TagUrlQueryParamChangedEvent'

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :successful, -> { completed.where(error_message: nil ) }

  after_create_commit { broadcast_replace_to "#{domain_id}_current_crawl", target: "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain }}
  after_update_commit { broadcast_replace_to "#{domain_id}_current_crawl", target: "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain }}

  def self.most_recent
    most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def found_tag!(
    tag_url,
    monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', 
    # should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', 
    should_run_audit: true,
    is_allowed_third_party_tag: false, 
    is_third_party_tag: true,
    initial_crawl: false,
    should_log_tag_checks: true,
    consider_query_param_changes_new_tag: false,
    performance_audit_iterations: (ENV['DEFAULT_PERFORMANCE_AUDIT_ITERATIONS'] || '5').to_i
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
        performance_audit_iterations: performance_audit_iterations
      }
    )
    url_to_audit = tag.urls_to_audit.create!(audit_url: url, display_url: url, tagsafe_hosted: false)
    url_to_audit.generate_tagsafe_hosted_site_now!
    # if it's the first time scanning the domain for tags, don't run the job
    # we may eventually move this into the job itself, but for now let's just not bother enqueuing
    AfterTagCreationJob.perform_later(tag) unless initial_crawl
    tag
  end

  # def unremove_tag_from_site!(tag)
  #   TagRemovedFromSiteEvent.create!(triggerer: tag)
  # end

  # def query_params_changed_for_tag!(tag, new_full_url)
  #   parsed_new_url = URI.parse(new_full_url)
  #   TagUrlQueryParamsChangedEvent.create!(triggerer: tag, metadata: {
  #     removed_url_query_params: url_query_param, 
  #     added_url_query_params: parsed_new_url.query 
  #   })
  # end

  # def tag_removed_from_site!(tag)
  #   removed_from_site_tag_events.create!(tag: tag)
  # end

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