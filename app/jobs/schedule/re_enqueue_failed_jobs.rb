module Schedule
  class ReEnqueueFailedJobs < ApplicationJob
    queue_as TagsafeQueue.CRITICAL

    def perform
      start_time = Time.now

      redis = Resque.redis
      Rails.logger.info "Beginning Schedule::ReEnqueueFailsJobs with #{Resque::Failure.count} failed jobs to check."
      re_enqueued_jobs = 0
      (0...Resque::Failure.count).each do |i|
        serialized_job = redis.lindex(:failed, i)
        job = Resque.decode(serialized_job)
  
        next if job.nil?
        if job['exception'] == 'Resque::DirtyExit'
          re_enqueued_jobs += 1
          Rails.logger.info "Schedule::ReEnqueueFailedJobs picked up a DirtyExit failed job, retrying: #{job.dig('payload', 'args', 0, 'job_class')}"
          Resque::Failure.requeue(i)
          Resque::Failure.remove(i)
        end
      end

      Rails.logger.info "Completed Schedule::ReEnqueueFailedJobs in #{Time.now - start_time} seconds with #{re_enqueued_jobs} re enqueued jobs."
    end
  end
end