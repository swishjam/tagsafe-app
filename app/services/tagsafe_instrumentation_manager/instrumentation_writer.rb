module TagsafeInstrumentationManager
  class InstrumentationWriter
    def initialize(container, type: 'tag-manager')
      @container = container
      @type = type
      raise "Invalid type: #{type}, must be either `tag-manager` or `speed-optimization`." unless ['tag-manager', 'speed-optimization'].include?(type)
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
      @instrumentation_compiler ||= InstrumentationCompiler.new(@container, @type)
    end

    def instrumentation_aws_handler
      @instrumentation_aws_handler ||= InstrumentationAwsHandler.new(@container, @type)
    end
  end
end