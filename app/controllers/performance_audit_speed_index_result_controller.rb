class PerformanceAuditSpeedIndexResultController < LoggedInController
  def index
    audit = current_container.audits.find_by(uid: params[:uid])
    with_tag_frames = audit.median_individual_performance_audit_with_tag.performance_audit_speed_index_frames
    without_tag_frames = audit.median_individual_performance_audit_without_tag.performance_audit_speed_index_frames
    visual_progress_chart_data = [
      { name: 'Visual progress with tag', data: with_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } },
      { name: 'Visual progress without tag', data: without_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } }
    ]
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit.uid}_performance_audit_speed_index_result",
      partial: 'performance_audit_speed_index_result/index',
      locals: {
        audit: audit,
        with_tag_frames: with_tag_frames.where.not(s3_url: nil),
        without_tag_frames: without_tag_frames.where.not(s3_url: nil),
        visual_progress_chart_data: visual_progress_chart_data
      }
    )
  end
end