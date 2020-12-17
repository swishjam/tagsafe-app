class ScriptSubscriberLintResult < ApplicationRecord
  belongs_to :script_subscriber
  belongs_to :lint_result
end