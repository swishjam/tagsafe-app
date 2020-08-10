class ScriptChangesController < ApplicationController
  before_action :authorize!

  def index
    monitored_script = MonitoredScript.find(params[:monitored_script_id])
    ensure_organization_is_subscribed(monitored_script)

    @script_changes = ScriptChange.where(monitored_script_id: params[:monitored_script_id])
  end

  def content
    script_change = ScriptChange.find(params[:id])
    diff = Diffy::SplitDiff.new(script_change.previous_change.content, script_change.content, format: :html)

    @new_script = diff.left.html_safe
    @previous_script = diff.right.html_safe
  end

  def show
    @script_change = ScriptChange.find(params[:id])
    ensure_organization_is_subscribed(@script_change.monitored_script)
  end
end