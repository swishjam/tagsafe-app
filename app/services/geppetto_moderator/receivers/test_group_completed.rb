class GeppettoModerator::Receivers::TestGroupCompleted
  def initialize(test_results_with_current_tag:, test_results_with_previous_tag:, test_results_without_tag:, test_group_run_id:)
    @test_results_with_current_tag = test_results_with_current_tag
    @test_results_with_previous_tag = test_results_with_previous_tag
    @test_results_without_tag = test_results_without_tag
    @test_group_run_id = test_group_run_id
    # @script_change_id = script_change_id
    # @execution_reason_id = execution_reason_id
    # @test_subscriber_id = test_subscriber_id
    @test_runs = []
  end

  def receive!
    create_test_runs
    evaluate_results
    test_group_run.completed!
  end

  private

  def evaluate_results
    TestResultsManager::Evaluator.new(test_group_run).evaluate!
  end

  def create_test_runs
    @test_results_with_current_tag.each{ |res| create_test_run(res, ScriptTestType.CURRENT_TAG) }
    @test_results_with_previous_tag.each{ |res| create_test_run(res, ScriptTestType.PREVIOUS_TAG) }
    @test_results_without_tag.each{ |res| create_test_run(res, ScriptTestType.WITHOUT_TAG) }
  end

  def create_test_run(results, script_test_type)
    TestRun.create(
      results: results['results'],
      script_test_type: script_test_type,
      test_subscriber_id: @test_subscriber_id,
      script_change_id: @script_change_id,
      test_group_run_id: test_group_run.id,
      created_at: DateTime.now
    )
  end

  def test_subscriber
    @test_subscriber ||= TestSubscriber.find(@test_subscriber_id)
  end

  def test_group_run
    @test_group_run ||= TestGroupRun.find(@test_group_run_id)
  end
end