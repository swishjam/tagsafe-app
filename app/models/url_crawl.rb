class UrlCrawl < ApplicationRecord
  include HasExecutedStepFunction
  include HasCompletedAt
  include HasErrorMessage
  include Streamable
  # acts_as_paranoid
  
  belongs_to :domain
  belongs_to :page_url
  has_one :domain_audit
  has_many :retrieved_urls, class_name: UrlCrawlRetrievedUrl.to_s, dependent: :destroy
  has_many :found_tags, class_name: Tag.to_s, foreign_key: :found_on_url_crawl_id
  alias tags_found found_tags

  scope :resulted_in_created_tags, -> { includes(:found_tags).where.not(found_tags: { id: nil }) }
    
  after_create_commit { CrawlUrlJob.perform_later(self) }
  after_update_commit { broadcast_replace_to "#{uid}_url_crawl", target: "#{uid}_url_crawl", partial: 'url_crawls/status', locals: { url_crawl: self } }
  
  set_seconds_to_complete_timestamp created_at_column: :enqueued_at
  after_failure :completed!
  after_complete :handle_after_complete_for_domain_audit
  after_complete :run_tagsafe_provided_audit_if_necessary
  after_complete :ensure_tags_were_found_if_its_the_first_attempt

  attribute :enqueued_at, default: Time.now

  def self.most_recent
    most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def found_tag!(
    tag_url,
    byte_size:,
    load_type: 'async',
    release_check_minute_interval: 0,
    scheduled_audit_minute_interval: 0,
    is_allowed_third_party_tag: false, 
    is_third_party_tag: true,
    consider_query_param_changes_new_tag: false,
    has_content: true
  )
    # parsed_url = URI.parse(tag_url)
    tag = found_tags.create!(
      domain: domain,
      full_url: tag_url,
      # url_domain: parsed_url.host,
      # url_path: parsed_url.path,
      # url_query_param: parsed_url.query,
      load_type: load_type,
      found_on_page_url: page_url,
      has_content: has_content,
      last_seen_in_url_crawl_at: Time.current,
      last_captured_byte_size: byte_size,
      urls_to_audit_attributes: [{ page_url: page_url }],
      tag_preferences_attributes: {
        release_check_minute_interval: release_check_minute_interval,
        scheduled_audit_minute_interval: scheduled_audit_minute_interval,
        is_allowed_third_party_tag: is_allowed_third_party_tag,
        is_third_party_tag: is_third_party_tag,
        consider_query_param_changes_new_tag: consider_query_param_changes_new_tag
      }
    )
    # url_to_audit.generate_tagsafe_hosted_site_now! if Flag.flag_is_true(domain.organization, 'tagsafe_hosted_site_enabled')
  rescue => e
    Sentry.capture_exception(e)
    Rails.logger.error "Tried adding #{tag_url} to domain #{domain.url} but failed to save. Error: #{e.inspect}"
  end

  def is_for_domain_audit?
    domain_audit.present?
  end

  def is_first_crawl_for_domain_with_found_tags?
    domain.url_crawls.older_than(enqueued_at).resulted_in_created_tags.empty?
  end

  def percent_of_js_is_third_party
    ((num_third_party_bytes.to_f / (num_first_party_bytes + num_third_party_bytes))*100).round(2)
  end

  private 

  def handle_after_complete_for_domain_audit
    return unless is_for_domain_audit?
    update_domain_audit_details_view(domain_audit: domain_audit, now: true)
    unless found_tags.none?
      largest_tag = found_tags.order(last_captured_byte_size: :DESC).limit(1).first
      largest_tag.perform_audit_on_all_urls_on_current_tag_version!(execution_reason: ExecutionReason.TAGSAFE_PROVIDED)
    end
  end

  def run_tagsafe_provided_audit_if_necessary
    return if !is_first_crawl_for_domain_with_found_tags? || found_tags.none?
    largest_tag = found_tags.order(last_captured_byte_size: :DESC).limit(1).first
    largest_tag.perform_audit_on_all_urls_on_current_tag_version!(execution_reason: ExecutionReason.TAGSAFE_PROVIDED)
  end

  def ensure_tags_were_found_if_its_the_first_attempt
    # url_crawls_resulting_in_found_tags = domain.url_crawls.older_than(enqueued_at).resulted_in_created_tags.empty?
    # total_url_crawls = domain.url_crawls.count
    # return unless url_crawls_resulting_in_found_tags.none? && total_url_crawls.count < 5
  end
end