class OrganizationLintRule < ApplicationRecord
  belongs_to :lint_rule
  belongs_to :organization

  SEVERITY_DICTIONARY = {
    0 => "off",
    1 => "warn",
    2 => "error"
  }.freeze

  def severity_in_words
    SEVERITY_DICTIONARY[severity]
  end
end