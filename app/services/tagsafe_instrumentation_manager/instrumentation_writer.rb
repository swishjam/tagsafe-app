module TagsafeInstrumentationManager
  class InstrumentationWriter
    def initialize(domain)
      @domain = domain
    end

    def write_current_instrumentation_to_cdn
      instrumentation_compiler.compile_instrumentation
      instrumentation_aws_handler.write_domains_compiled_instrumentation_to_s3(instrumentation_compiler.compiled_instrumentation)
      instrumentation_aws_handler.purge_domains_instrumentation_cloudfront_cache
      # instrumentation_compiler.delete_compiled_instrumentation_file
    end

    private

    def instrumentation_compiler
      @instrumentation_compiler ||= InstrumentationCompiler.new(@domain)
    end

    def instrumentation_aws_handler
      @instrumentation_aws_handler ||= InstrumentationAwsHandler.new(@domain)
    end
  end
end