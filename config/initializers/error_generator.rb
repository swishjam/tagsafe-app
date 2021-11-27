class NoAccessError < StandardError; end;

class LambdaFunctionError
  class PayloadNotProvided < StandardError; end;
  class InvalidInvocation < StandardError; end;
  class InvalidFunctionArguments < StandardError; end;
  class FailedLambdaInvocation < StandardError; end;
end

class PerformanceAuditError
  class InvalidType < StandardError; end;
end

class AuditError
  class InvalidRetry < StandardError; end;
  class InvalidPrimary < StandardError; end;
end

class TagSafeHostedSiteError
  class AlreadyHosted < StandardError; end;
end

class TagError
  class InvalidUnremove < StandardError; end;
end

class LambdaResponseGeneratorError
  class MissingRequiredKey < StandardError; end;
end

class FlagError
  class FlagDoesntExist < StandardError; end;
end