class GenericTagSafeError < StandardError; end;
class NoAccessError < StandardError; end;

class TagsafeMailerError
  class InvalidArgumentsError < StandardError; end;
end

class LambdaFunctionError
  class PayloadNotProvided < StandardError; end;
  class InvalidInvocation < StandardError; end;
  class InvalidFunctionArguments < StandardError; end;
  class FailedLambdaInvocation < StandardError; end;
end

class LambdaEventResponseError
  class NoConsumerKlass < StandardError; end;
end

class PerformanceAuditError
  class InvalidType < StandardError; end;
  class NoPageTraceError < StandardError; end;
end

class FunctionalTestError
  class InvalidType < StandardError; end;
end

class HtmlSnapshotError
  class SnapshotFailed < StandardError; end;
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

class TagsafeAwsEventBridgeRuleError
  class DoesNotExist < StandardError; end;
end