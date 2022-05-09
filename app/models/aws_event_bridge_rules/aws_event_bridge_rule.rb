class AwsEventBridgeRule < ApplicationRecord
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  validates_uniqueness_of :name, scope: :region, message: "An `AwsEventBridgeRule` already exists with this name in this region."

  def enable!(force: false)
    return true unless disabled? || force
    TagsafeAws::EventBridge.enable_rule(name, region: region)
    update!(enabled: true)
  end
  alias enable_if_necessary enable!

  def disable!(force: false)
    return true unless enabled? || force
    TagsafeAws::EventBridge.disable_rule(name, region: region)
    update!(enabled: false)
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