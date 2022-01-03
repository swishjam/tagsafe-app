class DryTestRun < TestRun
  def self.friendly_class_name
    'Dry Run'
  end

  def after_passed
    functional_test.update!(passed_dry_run: true, run_on_all_tags: true)
    update_pending_dry_run_functional_test_view(now: true)
  end

  def after_failed
    functional_test.update!(passed_dry_run: false)
    update_pending_dry_run_functional_test_view(now: true)
  end

  def update_pending_dry_run_functional_test_view(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    partial = if failed?
                'test_runs/show_failed'
              elsif pending?
                'test_runs/show_pending'
              elsif passed?
                'test_runs/show_passed'
              end
    send(broadcast_method,
      "new_functional_test_view_stream",
      target: "test_run_#{uid}",
      partial: partial,
      locals: { functional_test: functional_test, test_run: self, streamed: true }
    )
    send(broadcast_method,
      "functional_test_#{functional_test.uid}_show_view_stream",
      target: "test_run_#{uid}",
      partial: partial,
      locals: { functional_test: functional_test, test_run: self, streamed: true }
    )
  end
end