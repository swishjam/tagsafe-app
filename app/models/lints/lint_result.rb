class LintResult < ApplicationRecord
  belongs_to :script_change
  has_many :script_subscriber_lint_results, dependent: :destroy
  has_many :script_subscribers, through: :script_subscriber_lints

  scope :by_script_change, -> (script_change) { where(script_change: script_change) }

  # validates_uniqueness_of :script_change_id, :line, :column, :rule_id
end