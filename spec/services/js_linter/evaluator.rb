require 'rails_helper'

RSpec.describe JsLinter::Evaluator do
  before(:each) do
    stub_geppetto_communication
    create_lint_rules
    allow_any_instance_of(ScriptChange).to receive(:content).and_return(File.read(Rails.root.join('spec', 'support', 'bad_javascript.js')))
    @expected_organization_lint_rules = Hash[LintRule::DEFAULT_RULES.collect{ |rule| [rule.to_s, 2] }]

    @organization_1 = create(:organization)
    @organization_2 = create(:organization, name: 'Anotha Org')

    @script = create(:script, url: 'https://cdn.thirdpartytag.com')
    @script_change = create(:script_change, script: @script)
    
    @domain_1 = create(:domain, url: 'https://www.tagsafe.io', organization: @organization_1)
    @script_subscriber_1 = create(:script_subscriber, script: @script, domain: @domain_1, first_script_change: @script_change)

    @domain_2 = create(:domain, url: 'https://www.google.com', organization: @organization_2)
    @script_subscriber_2 = create(:script_subscriber, script: @script, domain: @domain_2, first_script_change: @script_change)

    @linter_1 = JsLinter::Evaluator.new(@script_change, @script_subscriber_1)
    @linter_2 = JsLinter::Evaluator.new(@script_change, @script_subscriber_2)
  end

  describe '#evaluate!' do
    it 'creates a single Lint that each script_subscriber references through script_subscriber_lints' do
      expect(@linter_1).to receive(:capture_new_lint).exactly(1).times.and_call_original
      expect(@linter_1).to receive(:capture_existing_lint).exactly(0).times.and_call_original

      expect(@linter_2).to receive(:capture_existing_lint).exactly(1).times.and_call_original
      expect(@linter_2).to receive(:capture_new_lint).exactly(0).times.and_call_original

      expect(@script_subscriber_1.lints.count > 0).to be(false)
      @linter_1.evaluate!
      expect(@script_subscriber_1.lints.count > 0).to be(true)

      expect(@script_subscriber_2.lints.count > 0).to be(false)
      @linter_2.evaluate!
      expect(@script_subscriber_2.lints.count > 0).to be(true)

      expect(Lint.count).to eq(@script_subscriber_1.lints.count)
      expect(Lint.count).to eq(@script_subscriber_2.lints.count)
      expect(ScriptSubscriberLint.count).to eq(@script_subscriber_1.lints.count + @script_subscriber_2.lints.count)
    end

    it 'only creates a lint when the script_subscribers organization has the lint rule in place' do
      @organization_2.lint_rule_subscriptions.destroy_all
      @linter_2

      expect(@linter_1).to receive(:capture_new_lint).exactly(1).times.and_call_original
      expect(@linter_1).to receive(:capture_existing_lint).exactly(0).times.and_call_original

      expect(@linter_2).to receive(:capture_existing_lint).exactly(0).times.and_call_original
      expect(@linter_2).to receive(:capture_new_lint).exactly(0).times.and_call_original

      expect(@script_subscriber_1.lints.count > 0).to be(false)
      @linter_1.evaluate!
      expect(@script_subscriber_1.lints.count > 0).to be(true)

      expect(@script_subscriber_2.lints.count > 0).to be(false)
      @linter_2.evaluate!
      expect(@script_subscriber_2.lints.count > 0).to be(false)

      expect(Lint.count).to eq(@script_subscriber_1.lints.count)
      expect(@script_subscriber_2.lints.count).to eq(0)
      expect(ScriptSubscriberLint.count).to eq(@script_subscriber_1.lints.count + @script_subscriber_2.lints.count)
    end
  end

  describe '#lints' do
    it 'calls Eslintrb.lint with the correct arguments' do
      expect(Eslintrb).to receive(:lint).with(@script_change.content.force_encoding('UTF-8'), @expected_organization_lint_rules).exactly(2).time
      @linter_1.send(:lints)
      @linter_2.send(:lints)
    end
  end

  describe '#organization_linting_rules' do
    it "merges the organization's lint_rules into a usable hash for JS Hint" do
      expect(@linter_1.send(:organization_linting_rules)).to eq(@expected_organization_lint_rules)
      expect(@linter_2.send(:organization_linting_rules)).to eq(@expected_organization_lint_rules)
    end
  end
end