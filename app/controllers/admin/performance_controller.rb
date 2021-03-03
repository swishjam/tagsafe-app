module Admin
  class PerformanceController < BaseController
    def index
      # @completed_audit_ids = Audit.where('created_at > ?', 1.day.ago).pluck(:id)
    end
  end
end