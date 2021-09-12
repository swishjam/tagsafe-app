module ChartHelper
  class AdminAuditPerformanceData
    def initialize(start_time: 1.day.ago, grouped_by_minutes: 15)
      @start_time = start_time
      @grouped_by_minutes = grouped_by_minutes
    end

    def get_performance_data
      [
        {
          name: 'Performance Audit Completion Time (s)',
          data: Audit.completed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..Time.now).average(:seconds_to_complete)
        },
        {
          name: 'Total Performance Audits Conducted',
          data: Audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..Time.now).count
        },
        {
          name: 'Failed Performance Audits',
          data: Audit.failed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..Time.now).count
        }
      ]
    end
  end
end