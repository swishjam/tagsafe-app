class GeppettoModerator::Receivers::StandaloneTestCompleted
  def initialize(test_result:, test_id:, domain_id:)
    @test_result = test_result
    @test_id = test_id
    @domain_id = domain_id
  end

  def receive!
    TestRun.create(
      standalone_test_run_domain_id: @domain_id,
      test_id: @test_id,
      results: @test_result,
      test_exeecution_reason: TestExecutionReason.INITIAL_TEST
    )
  end
end