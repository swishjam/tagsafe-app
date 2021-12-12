class TestRunsController < LoggedInController
  def index
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:tag_version_id])
    audit = tag_version.audits.find(params[:audit_id])
    test_runs = audit.test_runs.includes(:functional_test)
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit.uid}_test_runs",
      partial: 'test_runs/index',
      locals: { test_runs: test_runs, audit: audit }
    )
  end
end