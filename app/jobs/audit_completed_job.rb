class AuditCompletedJob < ApplicationJob
  def perform(audit)
    NotificationModerator::AuditNotifier.new(audit).notify!
  end
end