class Domain < ApplicationRecord
  include Flaggable
  include Streamable
  uid_prefix 'dom'
  acts_as_paranoid

  # belongs_to :subscription_option
  has_one :subscription_plan
  has_one :default_audit_configuration, as: :parent, class_name: DefaultAuditConfiguration.to_s, dependent: :destroy
  has_many :domain_users, dependent: :destroy
  has_many :users, through: :domain_users
  has_many :user_invites, dependent: :destroy
  has_many :page_urls, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :audits, dependent: :destroy
  has_many :domain_audits, dependent: :destroy
  has_many :functional_tests, dependent: :destroy
  has_many :performance_audit_calculators, dependent: :destroy
  has_many :url_crawls, dependent: :destroy
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true
  # no longer enforce uniqueness on Domain URL. Any reprucussions...?
  # validates_uniqueness_of :url, message: Proc.new { |domain| "A Tagsafe domain already exists for #{domain.url}" }

  before_validation :strip_pathname_from_url
  before_validation :add_default_page_url, on: :create
  before_create :set_stripe_customer_id
  before_create :set_default_subscription_plan_if_necessary
  before_create :add_performance_audit_calculator_and_default_audit_configuration

  attribute :is_generating_third_party_impact_trial, default: false

  scope :registered, -> { where(is_generating_third_party_impact_trial: false) }
  scope :not_generating_third_party_impact_trial, -> { registered }
  scope :generating_third_party_impact_trial, -> { where(is_generating_third_party_impact_trial: true) }

  def parsed_domain_url
    u = URI.parse(url)
    "#{u.scheme}://#{u.hostname}"
  end

  def url_hostname
    URI.parse(url).hostname
  end

  def add_performance_audit_calculator_and_default_audit_configuration
    PerformanceAuditCalculator.create_default_calculator(self)
    DefaultAuditConfiguration.create_default_for_domain(self)
  end

  def add_default_page_url
    page_urls.new(full_url: url, should_scan_for_tags: !is_generating_third_party_impact_trial)
  end

  def add_url(full_url, should_scan_for_tags:)
    page_urls.create(full_url: full_url, should_scan_for_tags: should_scan_for_tags)
  end

  def set_stripe_customer_id
    self.stripe_customer_id = generate_new_stripe_customer.id
  end

  def generate_new_stripe_customer
    Stripe::Customer.create({ email: "domain-user@#{URI.parse(url).hostname}" })
  end

  def set_default_subscription_plan_if_necessary
    SubscriptionOption.BASIC.apply_to_domain(self) unless subscription_plan.present?
  end

  def selected_subscription_option
    subscription_plan.subscription_option
  end

  def num_audits_remaining_this_month
    num_successful_and_pending_performance_audits = audits.successful_performance_audit.more_recent_than_or_equal_to(DateTime.now.beginning_of_month).count + 
                                                      audits.pending_performance_audit.more_recent_than_or_equal_to(DateTime.now.beginning_of_month).count
    remaining = 50 - num_successful_and_pending_performance_audits
    remaining.negative? ? 0 : remaining
  end

  def is_registered?
    !is_generating_third_party_impact_trial
  end

  def mark_as_registered!
    return if is_registered?
    update!(is_generating_third_party_impact_trial: false)
    page_urls.each{ |page_url| page_url.update!(should_scan_for_tags: true) }
  end

  def strip_pathname_from_url
    parsed_url = URI.parse(url)
    self.url = "#{parsed_url.scheme}://#{parsed_url.hostname}"
  rescue URI::InvalidURIError => e
    errors.add(:base, "Invalid URL provided.")
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

  def crawl_and_capture_domains_tags
    page_urls.should_scan_for_tags.each{ |page_url| page_url.crawl_for_tags! }
  end

  def should_capture_tag?(url)
    non_third_party_url_patterns.none?{ |url_pattern| url.include?(url_pattern.pattern) } 
  end

  def crawl_in_progress?
    url_crawls.pending.any?
  end

  def user_can_initiate_crawl?(user)
    return false if user.nil?
    users.include?(user)
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