class LintRule < ApplicationRecord
  has_many :organization_lint_rules

  scope :by_rule, -> (rule) { where(rule: rule) }
  # TODO: Actually define real default rules
  DEFAULT_RULES = %i[
    no-async-promise-executor no-await-in-loop no-compare-neg-zero no-cond-assign no-console no-constant-condition no-control-regex no-debugger no-dupe-args no-dupe-else-if 
    no-dupe-keys no-duplicate-case no-empty no-empty-character-class no-ex-assign no-extra-boolean-cast no-extra-parens no-extra-semi no-func-assign no-import-assign
    no-inner-declarations no-invalid-regexp no-loss-of-precision no-obj-calls no-promise-executor-return no-prototype-builtins no-regex-spaces no-setter-return 
    no-sparse-arrays no-template-curly-in-string no-unexpected-multiline no-unreachable-loop no-unsafe-finally no-unsafe-negation no-unsafe-optional-chaining no-useless-backreference 
    require-atomic-updates use-isnan valid-typeof init-declarations no-delete-var no-label-var no-restricted-globals no-shadow no-shadow-restricted-names no-undef no-undef-init
    no-undefined no-unused-vars no-use-before-define unknown
  ]

  def self.DEFAULTS
    by_rule(DEFAULT_RULES)
  end
end