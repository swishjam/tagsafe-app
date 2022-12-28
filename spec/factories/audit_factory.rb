FactoryBot.define do
  factory :audit, aliases: [:completed_audit] do
    association :container
    association :tag_version
    association :tag
    association :execution_reason
    association :page_url
    association :initiated_by_container_user
    tagsafe_score { 95.2 }
    started_at { 20.minutes.ago }
    # completed_at { 5.minutes.ago }
    error_message { nil }
    audit_components_attributes {[
      attributes_for(:main_thread_execution_audit_component),
      attributes_for(:js_file_size_audit_component)
    ]}
  end
end

