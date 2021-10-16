class Organization < ApplicationRecord  
  uid_prefix 'org'
  acts_as_paranoid
  
  has_many :organization_users, dependent: :destroy
  has_many :users, through: :organization_users
  has_many :domains, dependent: :destroy
  has_many :tags, through: :domains
  has_many :scripts, through: :domains

  has_one :slack_settings, class_name: 'SlackSetting'

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

  def should_log_tag_checks
    true
  end

  def number_of_billed_audits(start_time: Time.now.beginning_of_month, end_time: Time.now.end_of_month)
    Audit.joins(:tag).where(created_at: start_time..end_time, 
                                          execution_reason: ExecutionReason.BILLABLE, 
                                          tags: { domain_id: domains.collect(&:id) }).count
  end

  def completed_slack_setup?
    !slack_settings.nil?
  end

  def slack_client
    @slack_client ||= SlackModerator::Client.new(slack_settings) if completed_slack_setup?
  end
end