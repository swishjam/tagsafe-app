class TagSnippetInjectionUrlRule < ApplicationRecord
  belongs_to :tag_snippet

  scope :inject_rules, -> { where(type: %w[TriggerIfUrlContainsTagSnippetInjectionRule]) }
  scope :dont_inject_rules, -> { where(type: %w[DontTriggerIfUrlContainsTagSnippetInjectionRule]) }
end