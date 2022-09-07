class AwsEventBridgeRule < ApplicationRecord
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  validates_uniqueness_of :name, scope: :region, message: "An `AwsEventBridgeRule` already exists with this name in this region."

  def enable!(force: false)
    if enabled? && !force
      Rails.logger.warn "`.enable!` called on AwsEventBridgeRule #{name} despite it already being enabled in Tagsafe's system, not making the call to AWS."
    else
      TagsafeAws::EventBridge.enable_rule(name, region: region)
      update!(enabled: true)
    end
  end
  alias enable_if_necessary enable!

  def disable!(force: false)
    if disabled? && !force
      Rails.logger.warn "`.disable!` called on AwsEventBridgeRule #{name} despite it already being disabled in Tagsafe's system, not making the call to AWS."
    else
      TagsafeAws::EventBridge.disable_rule(name, region: region)
      update!(enabled: false)
    end
  end

  def fetch_from_aws
    TagsafeAws::EventBridge.get_rule(name, region: region)
  end

  def tagsafe_state_matches_aws_state?
    fetch_from_aws.state == (disabled? ? 'DISABLED' : 'ENABLED')
  end

  def enabled?
    enabled
  end

  def disabled?
    !enabled
  end
end