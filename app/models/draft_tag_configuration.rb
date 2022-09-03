class DraftTagConfiguration < TagConfiguration
  after_create { tag.update!(has_staged_changes: true) }
  after_update { tag.update!(has_staged_changes: true) }

  def promote
    live_config = tag.live_tag_configuration
    if live_config
      live_config.update(promote_draft_config_params)
      tag.update!(has_staged_changes: false)
      live_config
    else
      live_config = LiveTagConfiguration.create(promote_draft_config_params)
      tag.update!(has_staged_changes: false)
      live_config
    end
  end

  def promote!
    live_config = tag.live_tag_configuration
    if live_config
      live_config.update!(promote_draft_config_params)
      tag.update!(has_staged_changes: false)
      live_config
    else
      live_config = LiveTagConfiguration.create!(promote_draft_config_params)
      tag.update!(has_staged_changes: false)
      live_config
    end
  end

  private

  def promote_draft_config_params
    {
      tag: tag,
      release_check_minute_interval: release_check_minute_interval,
      scheduled_audit_minute_interval: scheduled_audit_minute_interval,
      load_type: load_type,
      is_tagsafe_hosted: is_tagsafe_hosted,
      script_inject_priority: script_inject_priority,
      script_inject_location: script_inject_location,
      script_inject_event: script_inject_event,
      execute_script_in_web_worker: execute_script_in_web_worker,
      enabled: enabled
    }
  end
end