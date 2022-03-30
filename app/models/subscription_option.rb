class SubscriptionOption < ApplicationRecord
  has_many :subscription_plans
  has_many :domains, through: :subscription_plans

  FEATURES_DICTIONARY = {
    basic: [
      'Attributable performance impact for all of your tags.',
      '"Tagsafe Score" to stack rank your tags by health.',
      '50 audits per month, free of charge.',
      "Run ad-hoc audits.",
      "7 days of data retention."
    ],
    starter: [
      'All the features of the Basic Plan.',
      'Unlimited audits at $0.25/audit (first 50 free)',
      'Run audits on a schedule',
      'Release monitoring to identify when a tag provider makes changes to their tag.',
      'Run audits when your tag provider makes a release',
      'Run end-to-end functional tests to ensure tags do not impact functionality of your site',
      'Response time / uptime monitoring for each of your tags\' endpoints.'
    ],
    pro: [
      'All the features of the Basic and Starter Plan.',
      'Version control-like git diff views to identify changes between tag releases.',
      'Side-by-side screen recording videos of tags\' impact to your site\'s page load.',
      'Full waterfall view of page load resources for each audit.'
    ]
  }

  MONTHLY_PRICE_DICTIONARY = {
    basic: 0,
    starter: 99,
    pro: 199
  }

  def self.BASIC
    @free ||= find_by!(slug: 'basic')
  end

  def self.STARTER
    @starter ||= find_by!(slug: 'starter')
  end

  def self.PRO
    @pro ||= find_by!(slug: 'pro')
  end

  def basic?
    self == self.class.BASIC
  end

  def starter?
    self == self.class.STARTER
  end

  def pro?
    self == self.class.PRO
  end

  def apply_to_domain(domain)
    SubscriptionMaintainer::Applier.new(domain).set_subscription_for_domain(self)
  end

  def features
    self.class::FEATURES_DICTIONARY[slug.to_sym]
  end

  def price
    self.class::MONTHLY_PRICE_DICTIONARY[slug.to_sym]
  end

  def <=>(comparable)
    to_i <=> comparable.to_i
  end

  def >(comparable)
    to_i > comparable.to_i
  end

  def <(comparable)
    to_i < comparable.to_i
  end

  def to_i
    {
      'basic' => 0,
      'starter' => 1,
      'pro' => 2
    }[slug]
  end
end