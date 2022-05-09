def prepare_test!(options = {})
  stub_aws_calls unless options[:allow_aws_calls]
  @domain = create(:domain, url: 'https://www.tagsafe.io') unless options[:bypass_default_domain_create]
  create_execution_reasons unless options[:bypass_default_execution_reasons_create]
  create_aws_event_bridge_rules unless [:bypass_aws_event_bridge_rules]
  create_flags unless options[:bypass_flags]
end

def create_tag_with_associations(tag_factory: :tag, tag_url: 'https://www.test.com/script.js')
  url_crawl = create(:completed_url_crawl, 
    domain: @domain, 
    page_url: @domain.page_urls.first
  )
  tag = create(tag_factory,
    full_url: tag_url, 
    domain: @domain, 
    found_on_page_url: @domain.page_urls.first, 
    found_on_url_crawl: url_crawl
  )
  release_check = create(:release_check, tag: tag, captured_new_tag_version: true)
  TagManager::TagVersionCapturer.new(
    tag: tag, 
    content: '(function() { console.log("hello world"); })()', 
    release_check: release_check, 
    hashed_content: 'abc123', 
    bytes: 100
  ).capture_new_tag_version!
  url_to_audit = create(:url_to_audit, tag: tag, page_url: @domain.page_urls.first)
  tag
end

def stub_aws_calls
  allow_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::States::Client).to receive(:start_execution).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::EventBridge::Client).to receive(:disable_rule).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::EventBridge::Client).to receive(:enable_rule).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::S3::Client).to receive(:get_object).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::S3::Client).to receive(:delete_object).and_return(OpenStruct.new(status_code: 200))
  Aws.config.update(stub_responses: true)
end

def create_aws_event_bridge_rules
  create(:one_minute_release_check_aws_event_bridge_rule)
end

def stub_valid_page_url_enforcement
  allow(PageUrl).to receive(:get_valid_parsed_url) { |url| URI.parse(url) }
end

def stub_all_resque_jobs
  allow_any_instance_of(ApplicationJob).to receive(:perform).and_return(true)
end

def stub_enqueue_audits_after_create_callback
  allow_any_instance_of(Audit).to receive(:enqueue_configured_audit_types).and_return(true)
end

def stub_tag_version_job
  expect(NewTagVersionJob).to receive(:perform_later).at_least(:once).and_return('STUBBED')
end

def create_execution_reasons
  # run_rake_task('seed:mandatory_data')
  create(:initial_audit_execution)
  create(:manual_execution)
  create(:release_monitoring_activated)
  create(:scheduled_execution)
  create(:new_tag_version_execution)
  create(:retry_execution)
end

def create_flags
  # run_rake_task('seed:flags')
  create(:strip_all_images_in_performance_audits_flag)
  create(:strip_all_css_in_performance_audits_flag)
  create(:num_performance_audit_iterations_flag)
  create(:tagsafe_hosted_site_enabled_flag)
  create(:inline_injected_script_tags_flag)
  create(:include_performance_trace_flag)
  create(:max_individual_performance_audit_retries_flag)
  create(:include_page_load_resources_flag)
end

def run_rake_task(task)
  unless defined? @rake
    require 'rake'
    @rake = Rake.application
    @rake.init
    @rake.load_rakefile
  end
  @rake[task].invoke
end