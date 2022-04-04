class UrlCrawl < ApplicationRecord
  include HasExecutedLambdaFunction
  include HasCompletedAt
  include HasErrorMessage
  include Streamable
  acts_as_paranoid
  
  belongs_to :domain
  belongs_to :page_url
  has_one :domain_audit
  has_many :retrieved_urls, class_name: 'UrlCrawlRetrievedUrl', dependent: :destroy
  has_many :found_tags, class_name: 'Tag', foreign_key: :found_on_url_crawl_id
  alias tags_found found_tags

  scope :resulted_in_created_tags, -> { includes(:found_tags).where(found_tags: { id: nil }) }
    
  after_create_commit { CrawlUrlJob.perform_later(self) }
  after_update_commit { broadcast_replace_to "#{uid}_url_crawl", target: "#{uid}_url_crawl", partial: 'url_crawls/status', locals: { url_crawl: self } }
  
  set_seconds_to_complete_timestamp created_at_column: :enqueued_at
  after_failure :completed!
  after_complete :stream_to_domain_audit_view_if_necessary

  attribute :enqueued_at, default: Time.now

  def self.most_recent
    most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def found_tag!(
    tag_url,
    load_type: nil,
    tag_check_minute_interval: domain.tags.most_recent_first.first&.tag_preferences&.tag_check_minute_interval || nil,
    scheduled_audit_minute_interval: domain.tags.most_recent_first.first&.tag_preferences&.scheduled_audit_minute_interval || nil,
    is_allowed_third_party_tag: false, 
    is_third_party_tag: true,
    should_log_tag_checks: true,
    consider_query_param_changes_new_tag: false,
    has_content: true
  )
    parsed_url = URI.parse(tag_url)
    tag = found_tags.create!(
      domain: domain,
      full_url: tag_url,
      url_domain: parsed_url.host,
      url_path: parsed_url.path,
      url_query_param: parsed_url.query,
      # load_type: load_type,
      load_type: 'async',
      found_on_page_url: page_url,
      has_content: has_content,
      last_seen_in_url_crawl_at: Time.now,
      tag_preferences_attributes: {
        tag_check_minute_interval: tag_check_minute_interval,
        is_allowed_third_party_tag: is_allowed_third_party_tag,
        is_third_party_tag: is_third_party_tag,
        should_log_tag_checks: should_log_tag_checks,
        consider_query_param_changes_new_tag: consider_query_param_changes_new_tag
      }
    )
    url_to_audit = tag.urls_to_audit.create(page_url: page_url)
    # url_to_audit.generate_tagsafe_hosted_site_now! if Flag.flag_is_true(domain.organization, 'tagsafe_hosted_site_enabled')
    tag.run_tag_check_later!
  rescue => e
    Rails.logger.error "Tried adding #{tag_url} to domain #{domain.url} but failed to save. Error: #{e.inspect}"
  end

  def stream_to_domain_audit_view_if_necessary
    return unless is_for_domain_audit?
    update_domain_audit_details_view(domain_audit: domain_audit, now: true)
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
end