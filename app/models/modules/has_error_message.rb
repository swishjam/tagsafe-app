module HasErrorMessage
  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods
    base.scope :failed, -> { where.not(error_message: nil) }
    base.scope :successful, -> { where(error_message: nil) }
  end

  module ClassMethods
    def after_failure(method_name_or_proc = nil, &block)
      if block_given?
        after_failure_callbacks << block
      elsif method_name_or_proc
        after_failure_callbacks << method_name_or_proc
      end
    end
    alias after_failed after_failure

    def after_failure_callbacks
      @@after_failure_callbacks ||= []
    end
  end

  module InstanceMethods
    def failed!(err_msg)
      return false if failed?
      update!(error_message: err_msg)
      run_after_failure_callbacks!
      err_msg
    end
    alias errored! failed!

    def failed?
      !successful?
    end
    alias errored? failed?

    def successful?
      error_message.nil?
    end
    alias success? successful?

    private

    def run_after_failure_callbacks!
      self.class.after_failure_callbacks.each do |method_name_or_proc|
        if method_name_or_proc.is_a?(Proc)
          call_proc_with_defined_args(method_name_or_proc)
        elsif method_name_or_proc.is_a?(Symbol)
          call_method_with_defined_args(method_name_or_proc)
        end
      end
    end

    def call_proc_with_defined_args(proc)
      case proc.arity
      when 0
        proc.call
      else
        proc.call(self)
      end
    end

    def call_method_with_defined_args(method_name)
      case method(method_name).arity
      when -1, 0
        send(method_name)
      else
        send(method_name, self)
      end
    end
  end
end