def stub_script_valid_url_validation
  # expect_any_instance_of(Script).to receive(:valid_url).at_least(:once).and_return(true)
end

def stub_domain_scan
  expect_any_instance_of(GeppettoModerator::Senders::ScanDomain).to receive(:send!)
  # expect_any_instance_of(Domain).to receive(:scan_and_capture_domains_scripts)
end

def stub_geppetto_communication
  GeppettoModerator::Sender.any_instance.stub(:send!)
  # expect_any_instance_of(GeppettoModerator::Sender).to receive(:send!).at_least(:once).and_return('STUBBED')
end

def stub_script_changed_job
  expect(ScriptChangedJob).to receive(:perform_later).at_least(:once).and_return('STUBBED')
end

def stub_evaluate_script_job
  expect(ScriptManager::Evaluator).to receive(:new).at_least(:once).and_return(OpenStruct.new(evaluate!: "foo"))
end

def create_execution_reasons
  create(:manual_execution)
  create(:reactivated_script_execution)
  create(:scheduled_execution)
  create(:script_change_execution)
  create(:initial_test_execution)
  create(:test_execution)
end

def create_lint_rules
  %i[
    for-direction
    getter-return
    no-async-promise-executor
    no-await-in-loop
    no-compare-neg-zero
    no-cond-assign
    no-console
    no-constant-condition
    no-control-regex
    no-debugger
    no-dupe-args
    no-dupe-else-if
    no-dupe-keys
    no-duplicate-case
    no-empty
    no-empty-character-class
    no-ex-assign
    no-extra-boolean-cast
    no-extra-parens
    no-extra-semi
    no-func-assign
    no-import-assign
    no-inner-declarations
    no-invalid-regexp
    no-irregular-whitespace
    no-loss-of-precision
    no-misleading-character-class
    no-obj-calls
    no-promise-executor-return
    no-prototype-builtins
    no-regex-spaces
    no-setter-return
    no-sparse-arrays
    no-template-curly-in-string
    no-unexpected-multiline
    no-unreachable
    no-unreachable-loop
    no-unsafe-finally
    no-unsafe-negation
    no-unsafe-optional-chaining
    no-useless-backreference
    require-atomic-updates
    use-isnan
    valid-typeof
    init-declarations
    no-delete-var
    no-label-var
    no-restricted-globals
    no-shadow
    no-shadow-restricted-names
    no-undef
    no-undef-init
    no-undefined
    no-unused-vars
    no-use-before-define
    ].each do |rule|
      create("lint-rule-#{rule}".to_sym)
    end
end