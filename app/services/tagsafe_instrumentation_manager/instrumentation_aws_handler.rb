module TagsafeInstrumentationManager
  class InstrumentationAwsHandler
    def initialize(domain)
      @domain = domain
    end

    def write_domains_compiled_instrumentation_to_s3(compiled_instrumentation)
      TagsafeAws::S3.write_to_s3(
        bucket: 'tagsafe-instrumentation', 
        key: @domain.tagsafe_instrumentation_pathname, 
        content: compiled_instrumentation,
        acl: 'public-read'
      )
    end

    def purge_domains_instrumentation_cloudfront_cache
      TagsafeAws::CloudFront.invalidate_cache("/#{@domain.tagsafe_instrumentation_pathname}")
    end
  end
end