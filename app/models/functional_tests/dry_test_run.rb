class DryTestRun < TestRun
  def self.friendly_class_name
    'Dry Run'
  end

  def after_passed
    functional_test.update!(passed_dry_run: true, run_on_all_tags: true)
  end

  def after_failed
    functional_test.update!(passed_dry_run: false)
  end
end