class PerformanceAuditSpeedIndexResultController < LoggedInController
  def index
    if params[:is_for_domain_audit]
      audit_or_domain_audit = current_domain.domain_audits.find_by(uid: params[:uid])
      with_tag_frames = audit_or_domain_audit.median_individual_performance_audit_with_tags.performance_audit_speed_index_frames
      without_tag_frames = audit_or_domain_audit.median_individual_performance_audit_without_tags.performance_audit_speed_index_frames
      visual_progress_chart_data = [
        { name: 'Visual progress with third party tags', data: with_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } },
        { name: 'Visual progress without third party tags', data: without_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } }
      ]
    else
      audit_or_domain_audit = params[:is_for_domain_audit] ? current_domain.domain_audits.find_by(uid: params[:uid]) : current_domain.audits.find_by(uid: params[:uid])
      with_tag_frames = audit_or_domain_audit.median_individual_performance_audit_with_tag.performance_audit_speed_index_frames
      without_tag_frames = audit_or_domain_audit.median_individual_performance_audit_without_tag.performance_audit_speed_index_frames
      visual_progress_chart_data = [
        { name: 'Visual progress with tag', data: with_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } },
        { name: 'Visual progress without tag', data: without_tag_frames.collect{ |frame| [frame.ms_from_start, frame.progress] } }
      ]
    end
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit_or_domain_audit.uid}_performance_audit_speed_index_result",
      partial: 'performance_audit_speed_index_result/index',
      locals: {
        audit: audit_or_domain_audit,
        with_tag_frames: with_tag_frames.where.not(s3_url: nil),
        without_tag_frames: without_tag_frames.where.not(s3_url: nil),
        visual_progress_chart_data: visual_progress_chart_data
      }
    )
  end
end