class TestRunsController < LoggedInController
  def index
    @functional_test = current_domain.functional_tests.find(params[:functional_test_id])
    @test_runs = @functional_test.test_runs.most_recent_first(timestamp_column: :enqueued_at)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path },
      { text: "Test Suite", url: functional_tests_path },
      { text: "#{@functional_test.title} Test", url: functional_test_path(@functional_test) },
      { text: "#{@functional_test.title} Test Runs", active: true }
    )
  end

  def index_for_audit
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:tag_version_id])
    audit = tag_version.audits.find(params[:audit_id])
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit.uid}_test_runs",
      partial: 'test_runs/test_runs_table',
      locals: {
        for_audit: true,
        tag: tag,
        tag_version: tag_version,
        audit: audit,
        test_runs: audit.test_runs_with_tag.order(:passed),
        turbo_frame_tag_name: "audit_#{audit.uid}_test_runs",
        columns_to_exclude: ['Date', 'Type of Test'],
        empty_message_html: "<h5>No functional tests were run because you don't have any tests configured for this tag, <a href='#{functional_tests_path}' target='_top'>configure them here</a>.</h5>"
      }
    )
  end

  def show
    @functional_test = current_domain.functional_tests.find(params[:functional_test_id])
    @test_run = @functional_test.test_runs.find(params[:id])
    if params[:for_audit]
      @tag = current_domain.tags.find(params[:tag_id])
      @tag_version = @tag.tag_versions.find(params[:tag_version_id])
      @audit = @tag_version.audits.find(params[:audit_id])
      @include_audit_nav = true
      @back_link = { text: 'Back to all tests', url: test_runs_tag_tag_version_audit_path(@tag, @tag_version, @audit) }
      render_breadcrumbs(
        { url: tags_path, text: "Monitor Center" },
        { url: tag_path(@tag), text: "#{@tag.try_friendly_name} details" },
        { url: tag_tag_version_audits_path(@tag, @tag_version), text: "Version #{@tag_version.sha} audits" },
        { text: "#{@audit.created_at.formatted_short} audit", active: true }
      )
    else
      @back_link = { text: 'Back to all tests', url: functional_test_test_runs_path(@functional_test) }
      render_breadcrumbs(
        { text: 'Monitor Center', url: tags_path },
        { text: "Test Suite", url: functional_tests_path },
        { text: @functional_test.title, url: functional_test_path(@functional_test) },
        { text: "#{@functional_test.title} Test Runs", url: functional_test_test_runs_path(@functional_test) },
        { text: "Test Run Results", active: true }
      )
    end
  end

  def retry
    functional_test = current_domain.functional_tests.find(params[:functional_test_id])
    test_run = functional_test.test_runs.find(params[:id])
    test_run.retry!
    current_user.broadcast_notification("Re running functional test #{functional_test.title}")
    render status: :ok
  end
end