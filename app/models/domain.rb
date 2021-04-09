class Domain < ApplicationRecord
  belongs_to :organization
  has_many :domain_scans, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  after_create_commit do
    scan_and_capture_domains_scripts(true)
  end

  def add_tag!(
      tag_url,
      monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', 
      should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', 
      is_allowed_third_party_tag: false, 
      is_third_party_tag: true,
      initial_scan: false,
      should_log_tag_checks: true,
      consider_query_param_changes_new_tag: false,
      url_to_audit: url,
      num_test_iterations: 3
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
        url_to_audit: url_to_audit,
        num_test_iterations: num_test_iterations
      }
    )
    # if it's the first time scanning the domain for tags, don't run the job
    # we may eventually move this unless statement into the job itself, but for now let's just not bother enqueuing
    AfterTagCreationJob.perform_later(tag) unless initial_scan
    tag
  end

  def has_tag?(tag)
    tags.include? tag
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def scan_and_capture_domains_scripts(initial_scan = false)
    GeppettoModerator::Senders::ScanDomain.new(self, initial_scan: initial_scan).send!
  end

  def should_capture_tag?(url)
    non_third_party_url_patterns.none?{ |url_pattern| url.include?(url_pattern.pattern) } 
  end
end