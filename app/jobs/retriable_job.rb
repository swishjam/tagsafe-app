module RetriableJob
  def self.included(base)
    base.rescue_from StandardError do |exception|
      # executions includes the initial attempt
      if executions <= 3
        Resque.logger.warn "RetriableJob WARNING: Retrying #{self.class.to_s} for the #{executions} time after it failed with an error of #{exception.inspect}"
        retry_job wait: 5, queue: self.class.queue_as
      else
        Resque.logger.error "RetriableJob ERROR: #{self.class.to_s} failed after 3 retries with a final error of #{exception.inspect}"
        raise exception
      end
    end
  end

  # def self.apply_defaults_to_class(klass)
  #   klass.class_variable_set(:@@_max_retries, (ENV['DEFAULT_RETRIABLE_JOB_MAX_RETRIES'] || 3).to_i)
  #   klass.class_variable_set(:@@_rollback_db_transactions_on_failures, true)
  #   klass.class_variable_set(:@@_wait, 5)
  #   klass.class_variable_set(:@@_rescuable_errors, [StandardError])
  #   klass.class_variable_set(:@@_ignored_errors, [])
  # end

  # def self.apply_rescue_from_to_class(klass)
  #   binding.pry
  #   klass.rescue_from *(klass.class_variable_get(:@@_rescuable_errors) - klass.class_variable_get(:@@_ignored_errors)), with: -> (exception) { 
  #     binding.pry
  #     self.class.handle_failed_job(exception, executions) 
  #   }
  # end

  # def self.apply_perform_with_rollback_to_class(klass)
  #   klass.class_eval do
  #     def monkey_patch_perform!; end;
  #     def perform(*arguments)
  #       binding.pry
  #       if class_variable_get(:@@_rollback_db_transactions_on_failures)
  #         Rails.logger.info "Running `#{self.class.to_s}.perform` within AR transaction block."
  #         ActiveRecord::Base.transaction { super(arguments) }
  #       else
  #         super(arguments)
  #       end
  #     end
  #   end
  # end

  # module ClassMethods
  #   def handle_failed_job(exception, execution_count)
  #     binding.pry
  #     if execution_count <= @@_max_retries
  #       Resque.logger.warn "Rescuing and retrying #{self.class.to_s} from #{exception.inspect}, attempt number #{execution_count}"
  #       retry_job wait: @@_wait, queue: self.class.queue_as.to_sym
  #     else
  #       Resque.logger.error "Haulting JobRetrier after #{executions} retry attempts for class #{self.class.to_s}"
  #       Resque.logger.error "Final error: #{exception.inspect}"
  #       raise exception
  #     end
  #   end

  #   def max_retries(retries)
  #     @@_max_retries = retries
  #   end

  #   def rollback_db_transactions_on_failures(should_rollback)
  #     @@_rollback_on_failures = should_rollback
  #   end

  #   def seconds_between_retries(seconds)
  #     @@_wait = seconds
  #   end

  #   def rescuable_errors(*klasses)
  #     @@_rescuable_errors = klasses
  #   end

  #   def dont_rescue_from_errors(*klasses)
  #     @@_ignored_errors = klasses
  #   end
  # end
end