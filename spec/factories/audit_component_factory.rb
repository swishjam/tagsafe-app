FactoryBot.define do
  factory :audit_component do
    association :audit
    score { 91.24 }
    started_at { 5.minutes.ago }
    completed_at { 2.minutes.ago }
    error_message { nil }
  end

  factory :main_thread_execution_audit_component, parent: :audit_component, class: MainThreadExecutionAuditComponent do
    type { 'MainThreadExecutionAuditComponent' }
    score_weight { 0.8 }
  end

  factory :js_file_size_audit_component, parent: :audit_component, class: JsFileSizeAuditComponent do
    type { 'JsFileSizeAuditComponent' }
    score_weight { 0.2 }
  end
end

