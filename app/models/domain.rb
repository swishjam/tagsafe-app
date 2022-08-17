class Domain < ApplicationRecord
  include Flaggable
  include Streamable
  uid_prefix 'dom'
  acts_as_paranoid

  belongs_to :current_subscription_plan, class_name: SubscriptionPlan.to_s, optional: true
  has_one :general_configuration, as: :parent, class_name: GeneralConfiguration.to_s, dependent: :destroy
  has_one :subscription_features_configuration, dependent: :destroy
  has_one :feature_prices_in_credits, class_name: FeaturePriceInCredits.to_s, dependent: :destroy

  has_many :alert_configurations
  has_many :audits, dependent: :destroy
  has_many :credit_wallets, dependent: :destroy
  has_many :bulk_debits, through: :credit_wallets
  has_many :domain_audits, dependent: :destroy
  has_many :domain_users, dependent: :destroy
  has_many :users, through: :domain_users
  has_many :functional_tests, dependent: :destroy
  has_many :test_runs, through: :functional_tests
  has_many :non_third_party_url_patterns, dependent: :destroy
  has_many :page_urls, dependent: :destroy
  has_many :performance_audit_calculators, dependent: :destroy
  has_many :subscription_plans, dependent: :destroy
  # has_many :subscription_usage_record_updates
  has_many :tags, dependent: :destroy
  has_many :release_checks, through: :tags
  has_many :tag_versions, through: :tags
  has_many :uptime_checks, through: :tags
  has_many :uptime_regions_to_check, through: :tags
  has_many :user_invites, dependent: :destroy
  has_many :url_crawls, dependent: :destroy
  has_many :url_crawl_retrieved_urls, through: :url_crawls

  validates :url, presence: true

  before_validation :strip_pathname_from_url_and_initialize_page_url, on: :create
  before_create { self.stripe_customer_id = Stripe::Customer.create({ email: "user@#{url_hostname}" }).id }
  after_create { PerformanceAuditCalculator.create_default(self) }
  after_create { GeneralConfiguration.create_default_for_domain(self) }
  after_destroy do
    Stripe::Customer.delete(self.stripe_customer_id) unless Rails.env.production?
  rescue => e
    puts "Can't delete Stripe Customer: #{self.stripe_customer_id}: #{e.message}"
  end

  attribute :is_generating_third_party_impact_trial, default: false

  scope :registered, -> { where(is_generating_third_party_impact_trial: false) }
  scope :not_generating_third_party_impact_trial, -> { registered }
  scope :generating_third_party_impact_trial, -> { where(is_generating_third_party_impact_trial: true) }

  scope :has_valid_subscription, -> { joins(:current_subscription_plan).merge(SubscriptionPlan.not_delinquent).merge(SubscriptionPlan.not_canceled) }
  scope :has_invalid_subscription, -> { joins(:current_subscription_plan).merge(SubscriptionPlan.delinquent) }
  scope :on_free_trial, -> { joins(:current_subscription_plan).merge(SubscriptionPlan.trialing) }

  scope :has_wallet_with_credits, -> { joins(:credit_wallets).merge(CreditWallet.has_credits_remaining) }
  
  scope :where_subscription_features_configuration, -> (where_clause) { joins(:subscription_features_configuration).where(subscription_features_configuration: where_clause) }

  TEST_DOMAIN_HOSTNAME = 'www.tagsafe-test.com'.freeze

  def parsed_domain_url
    u = URI.parse(url)
    "#{u.scheme}://#{u.hostname}"
  end

  def tagsafe_instrumentation_url
    "https://#{ENV['TAGSAFE_INSTRUMENTATION_CLOUDFRONT_HOSTNAME']}/#{tagsafe_instrumentation_pathname}"
  end

  def tagsafe_instrumentation_pathname
    "#{uid}-instrumentation.js"
  end

  def is_test_domain?
    url_hostname == TEST_DOMAIN_HOSTNAME
  end

  def has_current_subscription_plan?
    current_subscription_plan_id.present?
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

  def credit_wallet_for_current_month_and_year
    CreditWallet.for_domain(self)
  end

  def current_performance_audit_calculator
    performance_audit_calculators.currently_active.limit(1).first
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def crawl_and_capture_domains_tags
    if is_generating_third_party_impact_trial
      page_urls.each{ |page_url| page_url.crawl_for_tags! }
    else
      page_urls.should_scan_for_tags.each{ |page_url| page_url.crawl_for_tags! }
    end
  end

  def should_capture_tag?(url)
    non_third_party_url_patterns.none?{ |url_pattern| url.include?(url_pattern.pattern) } 
  end

  def crawl_in_progress?
    url_crawls.pending.any?
  end

  def has_payment_method_on_file?
    stripe_payment_method_id.present?
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