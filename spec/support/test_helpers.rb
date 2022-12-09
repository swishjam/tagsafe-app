def prepare_test!(options = {})
  stub_aws_calls unless options[:allow_aws_calls]
  stub_stripe_calls unless options[:allow_stripe_calls]
  stub_instrumentation_build unless options[:allow_instrumentation_build]
  stub_tag_version_fetcher unless options[:allow_real_tag_version_fetches]
  unless options[:bypass_default_domain_create]
    stub_valid_page_url_enforcement unless options[:enforce_valid_page_url]
    @domain = create(:domain, url: 'https://www.tagsafe.io')
    create(:feature_price_in_credits, domain: @domain)
    create(:performance_audit_calculator, domain: @domain)
    create(:credit_wallet, domain: @domain)
  end
  create_execution_reasons unless options[:bypass_default_execution_reasons_create]
  create_aws_event_bridge_rules unless options[:bypass_aws_event_bridge_rules]
  create_uptime_regions unless options[:bypass_uptime_regions]
  # create_flags unless options[:bypass_flags]
end

def create_tag_with_associations(tag_factory: :tag, tag_url: 'https://www.test.com/script.js')
  tagsafe_js_events_batch = create(:tagsafe_js_events_batch, domain: @domain)
  tag = create(tag_factory, full_url: tag_url, domain: @domain, tagsafe_js_events_batch: tagsafe_js_events_batch)
  # url_to_audit = create(:url_to_audit, tag: tag, page_url: @domain.page_urls.first)
  tag
end

def create_audit_with_performance_audits(domain:, tag:, tag_version:, execution_reason: ExecutionReason.MANUAL)
  audit = create(:audit, 
    domain: domain, 
    tag: tag, 
    tag_version: tag_version, 
    execution_reason: execution_reason, 
    performance_audit_calculator: @domain.current_performance_audit_calculator,
    performance_audit_completed_at: nil
  )
  with_tag = create(:median_individual_performance_audit_with_tag, audit: audit)
  without_tag = create(:median_individual_performance_audit_without_tag, audit: audit)
  create(:average_delta_performance_audit, audit: audit, performance_audit_with_tag: with_tag, performance_audit_without_tag: without_tag)
  audit.update_column :performance_audit_completed_at, 1.minute.ago
  audit
end

def create_tag_version(
  tag:, 
  content: "(function() { console.log('Hello world!'); console.log('#{SecureRandom.hex(4)}'); })();", 
  hashed_content: SecureRandom.hex(4), 
  bytes: 100, 
  commit_message: 'Some commit message...',
  num_additions: 1,
  num_deletions: 1,
  total_changes: 2,
  timestamp: Time.current
)
  release_check_batch = create(:release_check_batch)
  release_check = create(:release_check, tag: tag, release_check_batch: release_check_batch)
  
  filename = "tag-version-#{hashed_content}.js"
  file  = File.open(filename, "w") 
  file.puts content.force_encoding('UTF-8')
  file.close
  js_file_data = { 
    io: File.open(filename), 
    filename: filename,
    content_type: 'text/javascript'
  }
  tv = TagVersion.create!(
    tag: tag,
    hashed_content: hashed_content,
    bytes: bytes,
    release_check_captured_with: release_check,
    js_file: js_file_data,
    formatted_js_file: js_file_data,
    commit_message: commit_message,
    num_additions: num_additions,
    num_deletions: num_deletions,
    total_changes: total_changes,
    created_at: timestamp,
    updated_at: timestamp
  )
  File.delete(filename)
  tv
end


def stub_tag_version_content
  allow_any_instance_of(TagVersion).to receive(:content).and_return('STUBBED TAGVERSION CONTENT!')
end

def stub_aws_calls
  puts "Stubbing AWS calls"
  allow_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::States::Client).to receive(:start_execution).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::EventBridge::Client).to receive(:disable_rule).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::EventBridge::Client).to receive(:enable_rule).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::S3::Client).to receive(:put_object).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::S3::Client).to receive(:get_object).and_return(OpenStruct.new(status_code: 200))
  allow_any_instance_of(Aws::S3::Client).to receive(:delete_object).and_return(OpenStruct.new(status_code: 200))
  Aws.config.update(stub_responses: true)
end

def stub_stripe_calls
  puts "Stubbing Stripe calls"
  allow(Stripe::Customer).to receive(:create).and_return(OpenStruct.new(id: "cust_#{SecureRandom.hex(4)}"))
  allow(Stripe::Subscription).to receive(:create).and_return(OpenStruct.new(id: "sub_#{SecureRandom.hex(4)}"))
end

def stub_instrumentation_build
  puts "Stubbing instrumentaiton build."
  allow_any_instance_of(TagsafeInstrumentationManager::InstrumentationWriter).to receive(:write_current_instrumentation_to_cdn).and_return(true)
end

def stub_tag_version_fetcher
  puts "Stubbing TagVersion fetch with fake content."
  allow_any_instance_of(TagManager::TagVersionFetcher).to receive(:fetch_tag_content!).and_return('(function() { console.log("foo!"); })();')
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
  create(:manual_execution)
  create(:release_monitoring_activated)
  create(:scheduled_execution)
  create(:new_release_execution)
  create(:tagsafe_provided_execution)
end

def create_uptime_regions
  create(:us_east_1)
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