class ScriptCheckerJob < ApplicationJob
  @queue = :script_checker_queue

  def perform
    Rails.logger.info "Hello from Resque!"
    Resque.logger.info "Hello from Resque 2.0"
    MonitoredScript.all.each { |script| script.evaluate_script_details }
  end
end


# When I run with scheduler:
# I, [2020-08-10T08:02:00.688551 #83451]  INFO -- : got: (Job{default} | ScriptCheckerJob | [])
# I, [2020-08-10T08:02:00.688610 #83451]  INFO -- : Running before_fork hooks with [(Job{default} | ScriptCheckerJob | [])]
# D, [2020-08-10T08:02:00.690677 #83451] DEBUG -- : resque-2.0.0: Forked 83495 at 1597071720
# I, [2020-08-10T08:02:00.696999 #83495]  INFO -- : Running after_fork hooks with [(Job{default} | ScriptCheckerJob | [])]
# I, [2020-08-10T08:02:00.702877 #83495]  INFO -- : done: (Job{default} | ScriptCheckerJob | [])

# When I run from console:
# I, [2020-08-10T08:03:15.886423 #83451]  INFO -- : got: (Job{default} | ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper | [{"job_class"=>"ScriptCheckerJob", "job_id"=>"65e89782-cdb2-4cad-b13b-4267a8ffd873", "provider_job_id"=>nil, "queue_name"=>"default", "priority"=>nil, "arguments"=>[], "executions"=>0, "locale"=>"en"}])
# I, [2020-08-10T08:03:15.886458 #83451]  INFO -- : Running before_fork hooks with [(Job{default} | ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper | [{"job_class"=>"ScriptCheckerJob", "job_id"=>"65e89782-cdb2-4cad-b13b-4267a8ffd873", "provider_job_id"=>nil, "queue_name"=>"default", "priority"=>nil, "arguments"=>[], "executions"=>0, "locale"=>"en"}])]
# D, [2020-08-10T08:03:15.888035 #83451] DEBUG -- : resque-2.0.0: Forked 83520 at 1597071795
# I, [2020-08-10T08:03:15.894526 #83520]  INFO -- : Running after_fork hooks with [(Job{default} | ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper | [{"job_class"=>"ScriptCheckerJob", "job_id"=>"65e89782-cdb2-4cad-b13b-4267a8ffd873", "provider_job_id"=>nil, "queue_name"=>"default", "priority"=>nil, "arguments"=>[], "executions"=>0, "locale"=>"en"}])]
# I, [2020-08-10T08:03:15.971862 #83520]  INFO -- : Hello from Resque 2.0
# I, [2020-08-10T08:03:16.380851 #83520]  INFO -- : done: (Job{default} | ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper | [{"job_class"=>"ScriptCheckerJob", "job_id"=>"65e89782-cdb2-4cad-b13b-4267a8ffd873", "provider_job_id"=>nil, "queue_name"=>"default", "priority"=>nil, "arguments"=>[], "executions"=>0, "locale"=>"en"}])