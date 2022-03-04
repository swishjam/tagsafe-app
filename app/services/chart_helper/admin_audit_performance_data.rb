module ChartHelper
  class AdminAuditPerformanceData
    def initialize(start_time: 1.day.ago, end_time: Time.now, grouped_by_minutes: 15)
      @start_time = start_time
      @end_time = end_time
      @grouped_by_minutes = grouped_by_minutes
    end

    def get_performance_data
      [
        {
          name: 'Audit Completion Time (s)',
          data: Audit.completed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..@end_time).average(:seconds_to_complete)
        },
        {
          name: 'Tagsafe Score Confidence Range',
          data: Audit.completed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..@end_time).average(:tagsafe_score_confidence_range)
        },
        {
          name: 'Num Performance Audits per Audit',
          data: Audit.completed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..@end_time).average(:num_performance_audit_sets_ran)
        },
        {
          name: 'Total Performance Audits Conducted',
          data: Audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..@end_time).count
        },
        {
          name: 'Failed Performance Audits',
          data: Audit.failed_performance_audit.group_by_minute(:created_at, n: @grouped_by_minutes, range: @start_time..@end_time).count
        }
      ]
    end
  end
end