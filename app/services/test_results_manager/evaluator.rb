class TestResultsManager::Evaluator
  def initialize(test_group_run)
    @test_group_run = test_group_run
    @has_failed_test_runs = false
  end

  def evaluate!
    @test_group_run.test_runs.each do |test_run|
      passed = test_run.evaluate_success!
      @has_failed_test_runs = true unless passed
    end
    @test_group_run.update(passed: !@has_failed_test_runs)
  end
end