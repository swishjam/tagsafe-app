class ScriptSubscriberAllowedPerformanceAuditTag < ApplicationRecord
  belongs_to :script_subscriber, class_name: 'ScriptSubscriber'
end