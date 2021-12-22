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

  def show
    @functional_test = current_domain.functional_tests.find(params[:functional_test_id])
    @test_run = @functional_test.test_runs.find(params[:id])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path },
      { text: "Test Suite", url: functional_tests_path },
      { text: @functional_test.title, url: functional_test_path(@functional_test) },
      { text: "#{@functional_test.title} Test Runs", url: functional_test_test_runs_path(@functional_test) },
      { text: "Test Run Results", active: true }
    )
  end
  
  # def index
  #   tag = current_domain.tags.find(params[:tag_id])
  #   tag_version = tag.tag_versions.find(params[:tag_version_id])
  #   audit = tag_version.audits.find(params[:audit_id])
  #   test_runs = audit.test_runs.includes(:functional_test)
  #   render turbo_stream: turbo_stream.replace(
  #     "audit_#{audit.uid}_test_runs",
  #     partial: 'test_runs/index',
  #     locals: { test_runs: test_runs, audit: audit }
  #   )
  # end

  # def show
  #   @audit = Audit.find(params[:audit_id])
  #   @test_run = @audit.test_runs.includes(:functional_test).find(params[:id])
  # end
end