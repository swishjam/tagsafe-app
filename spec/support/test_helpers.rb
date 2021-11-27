def prepare_test!(options = {})
  stub_lambda_calls unless options[:allow_lambda_calls]
  @organization = create(:organization) unless options[:bypass_default_organization_create]
  @domain = create(:domain, organization: @organization) unless options[:bypass_default_organization_create] || options[:bypass_default_domain_create]
  create_execution_reasons unless options[:bypass_default_execution_reasons_create]
  create_flags unless options[:bypass_flags]
end

def stub_lambda_calls
  allow_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return(OpenStruct.new(status_code: 200))
end

def stub_tag_version_job
  expect(NewTagVersionJob).to receive(:perform_later).at_least(:once).and_return('STUBBED')
end

def create_execution_reasons
  # run_rake_task('seed:mandatory_data')
  create(:initial_audit_execution)
  create(:manual_execution)
  create(:reactivated_tag_execution)
  create(:scheduled_execution)
  create(:tag_change_execution)
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