module TagsafeInstrumentationManager
  class InstrumentationWriter
    def initialize(container)
      @container = container
    end

    def write_current_instrumentation_to_cdn
      instrumentation_compiler.delete_compiled_instrumentation_file
      instrumentation_compiler.compile_instrumentation
      instrumentation_aws_handler.write_containers_compiled_instrumentation_to_s3(instrumentation_compiler.compiled_instrumentation)
      instrumentation_aws_handler.purge_containers_instrumentation_cloudfront_cache
      instrumentation_compiler.delete_compiled_instrumentation_file
      @container.tagsafe_instrumentation_url
    end

    private

    def instrumentation_compiler
      @instrumentation_compiler ||= InstrumentationCompiler.new(@container)
    end

    def instrumentation_aws_handler
      @instrumentation_aws_handler ||= InstrumentationAwsHandler.new(@container)
    end
  end
end