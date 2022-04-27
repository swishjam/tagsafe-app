class DomainAudit < ApplicationRecord
  include Streamable
  include HasCompletedAt
  include HasErrorMessage
  belongs_to :domain
  belongs_to :page_url
  belongs_to :url_crawl
  
  has_many :performance_audits, dependent: :destroy
  has_many :individual_performance_audits_with_tags, class_name: IndividualPerformanceAuditWithTag.to_s
  has_many :individual_performance_audits_without_tags, class_name: IndividualPerformanceAuditWithoutTag.to_s
  has_one :median_individual_performance_audit_with_tags, class_name: MedianIndividualPerformanceAuditWithTag.to_s
  has_one :median_individual_performance_audit_without_tags, class_name: MedianIndividualPerformanceAuditWithoutTag.to_s
  has_one :average_performance_audit_with_tag, class_name: AveragePerformanceAuditWithTag.to_s
  has_one :average_performance_audit_without_tag, class_name: AveragePerformanceAuditWithoutTag.to_s

  has_many :delta_performance_audits, dependent: :destroy
  has_one :average_delta_performance_audit, class_name: AverageDeltaPerformanceAudit.to_s
  has_one :median_delta_performance_audit, class_name: MedianDeltaPerformanceAudit.to_s
  has_many :individual_delta_performance_audits, class_name: IndividualDeltaPerformanceAudit.to_s

  scope :completed_successfully, -> { completed.successful }

  after_failure :completed!
  after_complete :create_delta_performance_audits
  after_complete -> (domain_audit) { domain_audit.update_domain_audit_performance_impact_view(domain_audit: domain_audit, now: true) }
  before_validation { self.url_crawl = UrlCrawl.new(domain: domain, page_url: page_url) }

  after_create_commit do
    unless domain.is_test_domain?
      if Util.env_is_true('RUN_DOMAIN_AUDIT_IN_WEB_REQUEST')
        AuditRunnerJobs::RunDomainAudit.perform_now(self)
      else
        AuditRunnerJobs::RunDomainAudit.perform_later(self)
      end
    end
  end

  def create_delta_performance_audits
    return if failed?
    PerformanceAuditManager::AveragePerformanceAuditsCreator.new(self).create_average_performance_audits!
    PerformanceAuditManager::MedianPerformanceAuditsCreator.new(self).find_and_apply_median_audits!
  end

  def has_puppeteer_recording?
    median_individual_performance_audit_with_tags&.puppeteer_recording&.captured_successfully? == true && 
      median_individual_performance_audit_without_tags&.puppeteer_recording&.captured_successfully? == true
  end

  # alias scopes for PerformanceAuditManager :/
  def individual_performance_audits_with_tag
    individual_performance_audits_with_tags
  end

  def individual_performance_audits_without_tag
    individual_performance_audits_without_tags
  end
end