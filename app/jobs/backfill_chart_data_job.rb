# class BackfillChartDataJob < ApplicationJob
#   # This job runs each time a 'TAG_CHANGE' audit completes. Backfill the chart data with the domain's
#   # scripts with their primary audit data for the script change timestamp
#   # it is safe to assume the script_that_changed is the domain's most recent script change, therefore we can use
#   # each script's most recent change's audit.
#   def perform(audit_that_triggered_backfill)
#     audit_that_triggered_backfill.script_subscriber.domain.script_subscriptions.still_on_site.active.each do |script_subscription|
#       most_recent_primary_audit = script_subscription.primary_audit_by_script_change(script_subscription.script.most_recent_change)
#       if most_recent_primary_audit
#         ChartData.create(audit: most_recent_primary_audit, timestamp: audit_that_triggered_backfill.script_change.created_at)
#       else
#         Rails.logger.error "No primary audit to backfill for script subscriber #{script_subscription.id} for it's most recent script change of #{script_subscription.script.most_recent_change}"
#       end
#     end
#   end
# end