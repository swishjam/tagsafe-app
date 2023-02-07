module TagsafeInstrumentationManager
  class InstrumentationAwsHandler
    def initialize(container, type = 'tag-manager')
      @container = container
      @type = type
    end

    def write_containers_compiled_instrumentation_to_s3(compiled_instrumentation)
      TagsafeAws::S3.write_to_s3(
        bucket: "tagsafe-#{Rails.env}-instrumentation", 
        key: @type == 'tag-manager' ? @container.tagsafe_instrumentation_pathname : @container.tagsafe_speed_optimizer_instrumentation_pathname, 
        content: compiled_instrumentation,
        cache_control: "public, max-age=#{@container.instrumentation_cache_seconds}, stale-while-revalidate=60",
        acl: 'public-read',
        content_type: 'text/javascript'
      )
    end

    def purge_containers_instrumentation_cloudfront_cache
      TagsafeAws::CloudFront.invalidate_cache("/#{@type == 'tag-manager' ? @container.tagsafe_instrumentation_pathname : @container.tagsafe_speed_optimizer_instrumentation_pathname}")
    end
  end
end