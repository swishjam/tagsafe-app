class GeppettoModerator::Senders::RunStandaloneTest < GeppettoModerator::Senders::Base
  def initialize(domain:, test_to_run:)
    @endpoint = '/api/run_test'
    @domain = domain
    @test = test_to_run
  end

  def request_body
    {
      test_script: @test.test_script,
      test_id: @test.id
    }
  end
end