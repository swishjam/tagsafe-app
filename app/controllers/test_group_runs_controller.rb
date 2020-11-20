class TestGroupRunsController < ApplicationController
  before_action :authorize!
  def show
    script = Script.find(params[:script_id])
    permitted_to_view?(script)
    @test_group_run = TestGroupRun.includes(:test_runs).find(params[:id])
    @test_runs = @test_group_run.test_runs.group_by{ |run| run.script_test_type.name }
  end
end