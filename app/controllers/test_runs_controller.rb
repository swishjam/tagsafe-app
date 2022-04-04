class TestRunsController < LoggedInController
  def index
    @functional_test = current_domain.functional_tests.find(params[:functional_test_id])
    @test_runs = @functional_test.test_runs
                                  .most_recent_first(timestamp_column: :enqueued_at)
                                  .page(params[:page] || 1).per(params[:per_page] || 20)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path },
      { text: "Test Suite", url: functional_tests_path },
      { text: "#{@functional_test.title} Test", url: functional_test_path(@functional_test) },
      { text: "#{@functional_test.title} Test Runs", active: true }
    )
  end

  def index_for_audit
    tag = current_domain.tags.find(params[:tag_id])
    # tag_version = tag.tag_versions.find(params[:tag_version_id])
    audit = tag.audits.find(params[:audit_id])
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit.uid}_test_runs",
      partial: 'test_runs/test_runs_table',
      locals: {
        for_audit: true,
        tag: tag,
        # tag_version: tag_version,
        audit: audit,
        test_runs: audit.test_runs_with_tag.order(:passed).page(params[:page] || 1).per(params[:per_page] || 25),
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
      @audit = @test_run.audit
      @tag = @audit.tag
      @tag_version = @audit.tag_version
      @include_audit_nav = true
      @back_link = { text: 'Back to all tests', url: test_runs_tag_audit_path(@tag, @audit) }
      render_breadcrumbs(
        { url: tags_path, text: "Monitor Center" },
        { url: tag_path(@tag), text: "#{@tag.try_friendly_name} details" },
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
    retried_test_run = test_run.retry!
    current_user.broadcast_notification(message: "Re-running functional test #{functional_test.title}")
    if params[:for_audit]
      redirect_to functional_test_test_run_path(functional_test, retried_test_run, for_audit: true)
    else
      redirect_to functional_test_test_run_path(functional_test, retried_test_run)
    end
  end
end