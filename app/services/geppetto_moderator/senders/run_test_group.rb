class GeppettoModerator::Senders::RunTestGroup < GeppettoModerator::Senders::Base
  def initialize(script_change:, domain:, test_to_run:, execution_reason_id:, test_subscriber_id:)
    @endpoint = '/api/run_test_group'
    @domain = domain
    @test = test_to_run
    @script_change = script_change
    @execution_reason_id = execution_reason_id
    @test_subscriber_id = test_subscriber_id
  end

  private

  def request_body
    {
      tag_endpoint_to_test: endpoint_to_override,
      tag_endpoint_to_override_to: endpoint_to_override_to,
      test_script: @test.test_script,
      test_group_run_id: test_group_run.id,
      is_baseline_test: is_baseline_test
    }
  end

  def is_baseline_test
    @script_change.first_change?
  end

  def endpoint_to_override
    @script_change.script.url
  end

  def test_group_run
    @test_group_run ||= TestGroupRun.create(
      test_subscriber_id: @test_subscriber_id,
      script_change_id: @script_change.id,
      execution_reason_id: @execution_reason_id,
      enqueued_at: DateTime.now
    )
  end

  # assume this runs after the newest script_change was created, so use the previous js file
  def endpoint_to_override_to
    @script_change.first_change? ? nil : @script_change.previous_change.js_file_url
  end
end