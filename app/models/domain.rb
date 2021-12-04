class Domain < ApplicationRecord
  include Flaggable
  uid_prefix 'dom'
  acts_as_paranoid

  belongs_to :organization
  has_many :performance_audit_calculators
  has_many :url_crawls, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :urls_to_crawl, class_name: 'UrlToCrawl', dependent: :destroy
  has_many :url_crawls, dependent: :destroy
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validate :is_valid_url

  after_create_commit :add_defaults

  def parsed_domain_url
    u = URI.parse(url)
    "#{u.scheme}://#{u.hostname}"
  end

  def url_hostname
    URI.parse(url).hostname
  end

  def add_defaults(create_mock_site = true)
    urls_to_crawl.create(url: url)
    PerformanceAuditCalculator.create_default_calculator(self)
  end

  def current_performance_audit_calculator
    performance_audit_calculators.currently_active.limit(1).first
  end

  def disable_all_third_party_tags_during_audits
    # ENV['DISABLE_ALL_THIRD_PARTY_TAGS_IN_AUDITS'] === 'true'
    true
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def crawl_and_capture_domains_tags(initial_crawl = false)
    urls_to_crawl.each{ |url_to_crawl| url_to_crawl.crawl_later(initial_crawl) }
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

  ###################
  ## TURBO STREAMS ##
  ###################

  # really should just be used after the first Tag is created during onboarding
  def re_render_tags_table(empty: false, now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method,
      "domain_#{uid}_monitor_center_view_stream",
      target: "#{uid}_domain_tags_table",
      partial: 'server_loadable_partials/tags/tag_table',
      locals: { domain: self, tags: empty ? [] : tags.page(1).per(9), allow_empty_table: true }
    )
  end

  def re_render_tags_chart(now: false)
    return if ENV['DISABLE_CHART_UPDATE_STREAMS'] == 'true'
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    tags_to_chart = tags.includes(:tag_preferences).order('tag_preferences.enabled DESC, removed_from_site_at ASC, content_changed_at DESC').page(1).per(9)
    chart_data_getter = ChartHelper::TagsData.new(tags: tags_to_chart, start_time: 1.day.ago, end_time: Time.now, metric_key: :tagsafe_score)
    send(broadcast_method,
      "domain_#{uid}_monitor_center_view_stream",
      target: "#{uid}_domain_tags_chart",
      partial: 'charts/tags',
      locals: { 
        domain: self, 
        chart_data: chart_data_getter.chart_data, 
        displayed_metric: :tagsafe_score, 
        start_time: 1.day.ago, 
        end_time: Time.now, 
        streamed: true 
      }
    )
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