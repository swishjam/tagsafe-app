FactoryBot.define do
  factory :delta_lighthouse_audit do
    association :audit
    performance_score { -0.2 }
    type { 'DeltaLighthouseAudit' }
  end

  factory :current_tag_lighthouse_audit do
    association :audit
    performance_score { 0.4 }
    type { 'CurrentTagLighthouseAudit' }
  end

  factory :without_tag_lighthouse_audit do
    association :audit
    performance_score { 0.2 }
    type { 'WithoutTagLighthouseAudit' }
  end

  factory :average_current_tag_lighthouse_audit do
    association :audit
    performance_score { 0.4 }
    type { 'AverageCurrentTagLighthouseAudit' }
  end

  factory :average_without_tag_lighthouse_audit do
    association :audit
    performance_score { 0.2 }
    type { 'AverageWithoutTagLighthouseAudit' }
  end
end