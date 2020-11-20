class ExpectedTestResult < ApplicationRecord
  class InvalidOperatorError < StandardError; end

  VALID_OPERATORS = %w[equals greater_than less_than is_true]
  VALID_DATA_TYPES = %w[string float integer boolean JSON]

  validate :is_valid_operator
  validate :is_valid_data_type

  def passed?(test_result)
    case operator
    when "equals"
      equals?(test_result)
    when "greater_than"
      greater_than?(test_result)
    when "less_than"
      less_than?(test_result)
    else
      raise InvalidOperatorError
    end
  end

  def equals?(test_result)
    expected_result === test_result
  end

  def greater_than?(test_result)
    expected_result.to_f > test_result.to_f
  end

  def less_than?(test_result)
    expected_result.to_f > test_result.to_f
  end

  ###############
  # Validations #
  ###############
  def is_valid_data_type
    errors.add(:data_type, "is invalid.") unless VALID_DATA_TYPES.include? data_type
  end

  def is_valid_operator
    errors.add(:operator, "is invalid.") unless VALID_OPERATORS.include? operator
  end
end