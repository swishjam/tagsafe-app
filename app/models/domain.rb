class Domain < ApplicationRecord
  include Streamable
  uid_prefix 'dom'
  acts_as_paranoid

  has_one :general_configuration, as: :parent, class_name: GeneralConfiguration.to_s, dependent: :destroy

  has_many :tagsafe_js_events_batches, class_name: TagsafeJsEventsBatch.to_s, dependent: :destroy
  has_many :tag_url_patterns_to_not_capture, class_name: TagUrlPatternToNotCapture.to_s, dependent: :destroy
  has_many :alert_configurations, dependent: :destroy
  has_many :audits, dependent: :destroy
  has_many :domain_users, dependent: :destroy
  has_many :users, through: :domain_users
  has_many :functional_tests, dependent: :destroy
  has_many :test_runs, through: :functional_tests
  has_many :page_urls, dependent: :destroy
  has_many :performance_audit_calculators, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :release_checks, through: :tags
  has_many :tag_versions, through: :tags
  has_many :uptime_checks, through: :tags
  has_many :uptime_regions_to_check, through: :tags
  has_many :user_invites, dependent: :destroy

  validates :url, presence: true

  # before_validation :strip_pathname_from_url_and_initialize_page_url, on: :create
  before_create { self.instrumentation_key = "TAG-#{uid.split('dom_')[1]}" }
  after_create { TagsafeInstrumentationManager::InstrumentationWriter.new(self).write_current_instrumentation_to_cdn }
  after_destroy { TagsafeAws::S3.delete_object_by_s3_url(tagsafe_instrumentation_url(use_cdn: false)) }

  # attribute :is_generating_third_party_impact_trial, default: false
  attribute :tagsafe_js_reporting_sample_rate, default: 1.0
  validates :tagsafe_js_reporting_sample_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  TEST_DOMAIN_HOSTNAME = 'www.tagsafe-test.com'.freeze

  # TODO: hack until we re-name Domains -> Containers
  def name
    full_url
  end

  def parsed_domain_url
    u = URI.parse(url)
    "#{u.scheme}://#{u.hostname}"
  end

  def tagsafe_instrumentation_url(use_cdn: true)
    url_host = use_cdn ? ENV['CLOUDFRONT_HOSTNAME'] : 'tagsafe-instrumentation.s3.us-east-1.amazonaws.com'
    "https://#{url_host}/#{tagsafe_instrumentation_pathname}"
  end

  def tagsafe_instrumentation_pathname
    "#{instrumentation_key}/instrumentation.js"
  end

  def instrumentation_cache_seconds
    60 * 5 # 5 minutes, until configurable
  end

  def is_test_domain?
    url_hostname == TEST_DOMAIN_HOSTNAME
  end

  def url_hostname
    host = URI.parse(url).hostname
    host.slice!(host.last) if host.ends_with?('/')
    host
  end

  def add_url(full_url, should_scan_for_tags:)
    page_urls.create(full_url: full_url, should_scan_for_tags: should_scan_for_tags)
  end

  def is_registered?
    !is_generating_third_party_impact_trial
  end

  def mark_as_registered!
    return if is_registered?
    update!(is_generating_third_party_impact_trial: false)
    page_urls.each{ |page_url| page_url.update!(should_scan_for_tags: true) }
  end

  def strip_pathname_from_url_and_initialize_page_url
    page_url = page_urls.new(full_url: url, should_scan_for_tags: !is_generating_third_party_impact_trial)
    self.url = parsed_domain_url
  rescue URI::InvalidURIError => e
    errors.add(:base, "Invalid URL provided.")
  end

  def current_performance_audit_calculator
    performance_audit_calculators.currently_active.limit(1).first
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def admin_domain_users
    domain_users.by_role(Role.USER_ADMIN)
  end

  def add_user(user)
    users << user
  end

  def remove_user(user)
    if ou = domain_users.find_by(user_id: user.id)
      ou.destroy!
    end
  end


  #################
  ## VALIDATIONS ##
  #################

  def is_valid_url
    HTTParty.get(url)
  rescue => e
    errors.add(:base, "Cannot access #{url}, ensure this is a valid URL.")
  end
end