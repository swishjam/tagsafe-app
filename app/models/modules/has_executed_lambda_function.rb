module HasExecutedLambdaFunction
  def self.included(base)
    base.before_destroy { executed_lambda_function&.destroy! }
  end

  def executed_lambda_function
    ExecutedLambdaFunction.for(self)
  end
end