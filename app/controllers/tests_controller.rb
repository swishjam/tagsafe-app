class TestsController < ApplicationController
  before_action :authorize!

  def new
    @test = Test.new
  end

  def show
    @test = Test.find(params[:id])
    @test_subscriptions = current_domain.test_subscriptions.where(test_id: params[:id])
  end

  def create
    params[:test][:created_by_user_id] = current_user.id
    params[:test][:created_by_organization_id] = current_user.organization.id
    @test = Test.create(test_params)
    if @test.valid?
      # geppetto_job = @test.run_standalone_test(current_domain)
    else
      flash[:error] = @test.errors.full_messages.join('\n')
      redirect_to request.referrer
    end
  end

  def run_standalone_test
    @domain = Domain.find(params[:id])
    @test = Test.new
  end

  def post_standalone_test
    domain = Domain.find(params[:id])
    test_to_run = Test.create(test_script: params[:test][:test_script])
    results = test_to_run.run_standalone_test(domain)
    # redirect_to geppetto_job_path(results[:geppetto_job])
  end

  private

  def test_params
    params.require(:test).permit(:test_script, :title, :description, :created_by_user_id, :created_by_organization_id)
  end
end