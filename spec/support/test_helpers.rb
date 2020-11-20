def stub_script_valid_url_validation
  # expect_any_instance_of(Script).to receive(:valid_url).at_least(:once).and_return(true)
end

def stub_script_changed_job
  expect(ScriptChangedJob).to receive(:perform_later).at_least(:once).and_return('STUBBED')
end

def create_execution_reasons
  create(:manual_execution)
  create(:reactivated_script_execution)
  create(:scheduled_execution)
  create(:script_change_execution)
  create(:initial_test_execution)
  create(:test_execution)
end