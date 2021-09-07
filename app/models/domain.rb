class Domain < ApplicationRecord
  belongs_to :organization
  has_many :url_crawls, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :urls_to_crawl, dependent: :destroy, class_name: 'UrlToCrawl'
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  after_create_commit :add_default_url_to_scan

  def add_tag!(
      tag_url,
      found_on_url,
      monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', 
      should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', 
      is_allowed_third_party_tag: false, 
      is_third_party_tag: true,
      initial_scan: false,
      should_log_tag_checks: true,
      consider_query_param_changes_new_tag: false,
      url_to_audit: url,
      num_test_iterations: (ENV['DEFAULT_NUM_TEST_ITERATIONS'] || '5').to_i
    )
    parsed_url = URI.parse(tag_url)
    tag = tags.create!(
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
        url_to_audit: found_on_url,
        num_test_iterations: num_test_iterations
      }
    )
    # if it's the first time scanning the domain for tags, don't run the job
    # we may eventually move this into the job itself, but for now let's just not bother enqueuing
    AfterTagCreationJob.perform_later(tag) unless initial_scan
    tag
  end

  def add_default_url_to_scan
    # response = HTTParty.get(url) # validate url is accessible...?
    urls_to_scans.create(url: url)
  end

  def disable_all_third_party_tags_during_audits
    # ENV['DISABLE_ALL_THIRD_PARTY_TAGS_IN_AUDITS'] === 'true'
    false
  end

  def has_tag?(tag)
    tags.include? tag
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def crawl_and_capture_domains_tags(initial_scan = false)
    urls_to_crawl.each{ |url_to_crawl| url_to_crawl.crawl!(initial_scan) }
  end

  def should_capture_tag?(url)
    non_third_party_url_patterns.none?{ |url_pattern| url.include?(url_pattern.pattern) } 
  end

  def crawl_in_progress?
    url_crawls.pending.any?
  end

  def user_can_initiate_crawl?(user)
    return false if user.nil?
    organization.users.include?(user)
  end
end