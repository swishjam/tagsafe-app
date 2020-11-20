class TestSubscribersController < ApplicationController
  before_action :authorize!

  def index
    @test_subscriptions = current_domain.test_subscriptions.includes(:test, script_subscriber: :script).group_by(&:test)
  end

  def show
    @test_subscriber = TestSubscriber.find(params[:id])
  end

  def domain_tests
    domain = Domain.find(params[:id])
    @test_subscribers = TestSubscriber.includes(:scripts).where(domain_id: params[:id])
  end

  def script_tests
    script = Script.find(params[:id])
    permitted_to_view?(script)
    TestSubscriber.where(script_id: params[:id])
  end

  def enqueue_test_suite_for_script
    RunTestSuiteJob.perform_later(
      domain_id: params[:domain_id], 
      script_id: params[:script_id],
      script_change: nil,
      execution_reason: ExecutionReason.MANUAL
    )
    flash[:message] = "Running Test Suite for script id #{params[:script_id]} on domain id #{params[:domain_id]}"
    redirect_to script_path(params[:script_id])
  end
end