class DryTestRun < TestRun
  def after_passed
    functional_test.update!(passed_dry_run: true)
    update_pending_dry_run_functional_test_view(now: true)
  end

  def after_failed
    functional_test.update!(passed_dry_run: false)
    update_pending_dry_run_functional_test_view(now: true)
  end

  def update_pending_dry_run_functional_test_view(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method,
      "new_functional_test_view_stream",
      target: "functional_test_#{functional_test.uid}_pending_dry_run",
      partial: 'functional_tests/pending_dry_run',
      locals: { functional_test: functional_test, dry_test_run: self }
    )
    send(broadcast_method,
      "functional_test_#{functional_test.uid}_show_view_stream",
      target: "functional_test_#{functional_test.uid}_un_validated",
      partial: 'functional_tests/un_validated',
      locals: { functional_test: functional_test, dry_test_run: self }
    )
  end
end