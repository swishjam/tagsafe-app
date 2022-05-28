module MandatoryDataEnforcer
  class ExecutionReasons
    class << self
      
      def validate!
        create_execution_reasons_if_necessary
        Rails.logger.info "Validates all ExecutionReasons present."
      end

      private

      def create_execution_reasons_if_necessary
        ExecutionReason::TYPES_OF_EXECUTION_REASONS.each do |execution_reason_config|
          unless ExecutionReason.find_by(name: execution_reason_config[:name])
            puts "Creating #{execution_reason_config[:name]} Execution Reason."
            ExecutionReason.create!(name: execution_reason_config[:name])
          end
        end
      end

    end
  end
end