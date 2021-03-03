class Organization < ApplicationRecord
  has_many :organization_users, dependent: :destroy
  has_many :users, through: :organization_users
  has_many :domains, dependent: :destroy
  has_many :script_subscriptions, through: :domains
  has_many :scripts, through: :domains
  has_many :organization_lint_rules, dependent: :destroy
  has_many :lint_rules, through: :organization_lint_rules

  has_one :slack_settings, class_name: 'SlackSetting'

  after_create :add_default_linting_rules

  accepts_nested_attributes_for :domains

  def has_multiple_domains?
    domains.count > 1
  end

  def add_user(user)
    users << user
  end

  def remove_user(user)
    if ou = organization_users.find_by(user_id: user.id)
      ou.destroy!
    end
  end

  def number_of_billed_audits(start_time: Time.now.beginning_of_month, end_time: Time.now.end_of_month)
    Audit.joins(:script_subscriber).where(created_at: start_time..end_time, 
                                          execution_reason: ExecutionReason.BILLABLE, 
                                          script_subscribers: { domain_id: domains.collect(&:id) }).count
  end

  def add_default_linting_rules
    organization_lint_rules.create(LintRule.DEFAULTS.collect{ |rule| { lint_rule_id: rule.id }})
  end

  def completed_slack_setup?
    !slack_settings.nil?
  end

  def slack_client
    @slack_client ||= SlackModerator::Client.new(slack_settings) if completed_slack_setup?
  end
end