class IndividualPerformanceAudit < PerformanceAudit
  

  after_update_commit do
    broadcast_replace_to "#{id}_completion_indicator", 
                          target: "#{id}_completion_indicator", 
                          partial: 'individual_performance_audits/completion_indicator', 
                          locals: { individual_performance_audit: self }
  end

  def state
    return 'completed' if success?
    return 'pending' if pending?
    return 'failed' if failed?
  end
end