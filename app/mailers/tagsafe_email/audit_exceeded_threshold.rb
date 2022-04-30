module TagsafeEmail
  class AuditExceededThreshold < Base
    self.sendgrid_template_id = :'d-f6a83a79f43f4742a78aebfedc0e4f89'
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, audit)
      @to_email = user.email
      @template_variable = {
        tagsafe_score: audit.tagsafe_score,
        previous_tagsafe_score: audit.audit_to_compare_with&.tagsafe_score,
        tag_name: audit.tag.try_friendly_name,
        execution_reason: audit.execution_reason.name
      }
    end
  end
end