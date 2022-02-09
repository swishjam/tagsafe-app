module RetriableJob
  def self.included(base)
    base.rescue_from StandardError do |exception|
      # executions includes the initial attempt
      if !ENV['DONT_RETRY_JOBS'] && executions <= 3
        Resque.logger.warn "RetriableJob WARNING: Retrying #{self.class.to_s} for the #{executions} time after it failed with an error of #{exception.inspect}"
        retry_job wait: 5, queue: self.class.queue_as
      else
        Resque.logger.error "RetriableJob ERROR: #{self.class.to_s} failed after 3 retries with a final error of #{exception.inspect}"
        if base.respond_to?(:on_retriable_job_failure)
          base.on_retriable_job_failure(exception, *arguments)
        end
        raise exception
      end
    end
  end
end