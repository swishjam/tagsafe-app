module HasCompletedAt
  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods
    base.scope :pending, -> { where(completed_at: nil) }
    base.scope :completed, -> { where.not(completed_at: nil) }
  end

  module ClassMethods
    self.instance_variable_set(:@set_seconds_to_complete_timestamp,  false)
    self.instance_variable_set(:@after_complete_callbacks,  [])

    def after_complete(method_name_or_proc = nil, &block)
      if block_given?
        after_complete_callbacks << block
      elsif method_name_or_proc
        after_complete_callbacks << method_name_or_proc
      end
    end

    def after_complete_callbacks
      @after_complete_callbacks ||= []
    end

    def should_set_seconds_to_complete_timestamp?
      @set_seconds_to_complete_timestamp
    end

    def set_seconds_to_complete_timestamp(created_at_column: :created_at, seconds_to_complete_column: :seconds_to_complete)
      @set_seconds_to_complete_timestamp = true
      @seconds_to_complete_column = seconds_to_complete_column
      @created_at_column = created_at_column
    end

    def created_at_column
      @created_at_column
    end

    def seconds_to_complete_column
      @seconds_to_complete_column
    end
  end

  module InstanceMethods
    def completed!(*args)
      return false if completed?
      touch(:completed_at)
      update_column(self.class.seconds_to_complete_column, completed_at - send(self.class.created_at_column)) if self.class.should_set_seconds_to_complete_timestamp?
      run_after_complete_callbacks(*args)
      completed_at
    end

    def completed?
      !pending?
    end

    def pending?
      completed_at.nil?
    end

    private

    def run_after_complete_callbacks(*args)
      self.class.after_complete_callbacks.each do |method_name_or_proc|
        if method_name_or_proc.is_a?(Proc)
          call_proc_with_defined_args(method_name_or_proc, *args)
        elsif method_name_or_proc.is_a?(Symbol)
          call_method_with_defined_args(method_name_or_proc, *args)
        end
      end
    end

    def call_proc_with_defined_args(proc, *args)
      case proc.arity
      when 0
        proc.call
      when 1
        proc.call(self)
      else
        proc.call(self, *args)
      end
    end

    def call_method_with_defined_args(method_name, *args)
      case method(method_name).arity
      when 0
        send(method_name)
      when 1
        send(method_name, self)
      else
        send(method_name, self, *args)
      end
    end
  end
end