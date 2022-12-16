class Container < ApplicationRecord
  include Streamable
  uid_prefix 'cont'
  acts_as_paranoid

  has_many :instrumentation_builds, dependent: :destroy
  has_many :tagsafe_js_event_batches, class_name: TagsafeJsEventBatch.to_s, dependent: :destroy
  has_many :tag_url_patterns_to_not_capture, class_name: TagUrlPatternToNotCapture.to_s, dependent: :destroy
  has_many :alert_configurations, dependent: :destroy
  has_many :audits, dependent: :destroy
  has_many :container_users, dependent: :destroy
  has_many :users, through: :conatiner_users
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

  validates :name, presence: true

  before_create { self.instrumentation_key = "TAG-#{uid.split("#{self.class.get_uid_prefix}_")[1]}" }
  after_create :publish_instrumentation!
  after_destroy { TagsafeAws::S3.delete_object_by_s3_url(tagsafe_instrumentation_url(use_cdn: false)) }

  attribute :tagsafe_js_reporting_sample_rate, default: 0.05
  attribute :tagsafe_js_enabled, default: true

  validates :tagsafe_js_reporting_sample_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :tagsafe_js_enabled, presence: true

  def publish_instrumentation!
    TagsafeInstrumentationManager::InstrumentationWriter.new(self).write_current_instrumentation_to_cdn
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

  def has_tag?(tag)
    tags.include?(tag)
  end

  def add_user(user)
    users << user
  end

  def remove_user(user)
    if cu = container_users.find_by(user_id: user.id)
      cu.destroy!
    end
  end
end