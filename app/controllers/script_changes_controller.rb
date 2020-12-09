class ScriptChangesController < LoggedInController
  skip_before_action :authorize!, only: :content
  protect_from_forgery except: :content

  def show
    @script_change = ScriptChange.find(params[:id])
    permitted_to_view?(@script_change)
    @previous_script_change = @script_change.previous_change
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])

    diff = Diffy::SplitDiff.new(
      @previous_script_change&.content&.force_encoding('UTF-8'), 
      @script_change.content.force_encoding('UTF-8'), 
      format: :html, 
      include_plus_and_minus_in_html: true
    )

    @git_diff_script_change = diff.right.html_safe
    @git_diff_previous_script_change = diff.left.html_safe
    render_breadcrumbs(
      { url: scripts_path, text: "Monitor Center" },
      { url: script_subscriber_path(@script_subscriber), text: "#{@script_subscriber.try_friendly_name} Details" },
      { text: "#{@script_change.created_at.formatted} Tag Change", active: true}
    )
  end

  def content
    @content = ScriptChange.find(params[:id]).content
    render js: @content
  end

  def run_audit
    script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(script_subscriber, raise_error: true)
    script_change = ScriptChange.find(params[:id])
    script_subscriber.run_audit_for_script_change(script_change)
    display_toast_message("Performing audit on #{script_subscriber.try_friendly_name}")
    redirect_to request.referrer
  end
end