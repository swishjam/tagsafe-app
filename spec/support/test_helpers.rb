def prepare_test!(options = {})
  stub_lambda_calls unless options[:allow_lambda_calls]
  @organization = create(:organization) unless options[:bypass_default_organization_create]
  @domain = create(:domain, organization: @organization) unless options[:bypass_default_organization_create] || options[:bypass_default_domain_create]
  create_execution_reasons unless options[:bypass_default_execution_reasons_create]
end

def stub_lambda_calls
  allow_any_instance_of(Aws::Lambda::Client).to receive(:invoke).and_return(OpenStruct.new(status_code: 200))
end

def stub_tag_version_job
  expect(NewTagVersionJob).to receive(:perform_later).at_least(:once).and_return('STUBBED')
end

def create_execution_reasons
  create(:initial_audit_execution)
  create(:manual_execution)
  create(:reactivated_tag_execution)
  create(:scheduled_execution)
  create(:tag_change_execution)
  create(:retry_execution)
end