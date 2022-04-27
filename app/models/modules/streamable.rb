module Streamable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    ####################
    ## Domain streams ##
    ####################

    def stream_notification_to_all_domain_users(domain:, now: true, message: nil, partial: nil, partial_locals: {}, img: nil, timestamp: nil)
      raise "Must provide either `partial` or `message` param" if message == nil && partial == nil
      stream_prepend!(
        now: true,
        stream: "domain_#{domain.uid}_notifications_container", 
        target: "domain_#{domain.uid}_notifications_container", 
        partial: 'partials/notification', 
        locals: { 
          message: message, 
          partial: partial,
          image: img,
          timestamp: timestamp,
          partial_locals: partial_locals
        }
      )
    end

    # really should just be used after the first Tag is created during onboarding
    def re_render_tags_table(domain:, empty: false, now: false)
      stream_replace!(
        now: now,
        stream: "domain_#{domain.uid}_monitor_center_view_stream",
        target: "#{domain.uid}_domain_tags_table",
        partial: 'server_loadable_partials/tags/tag_table',
        locals: { domain: domain, tags: empty ? [] : domain.tags.page(1).per(9), allow_empty_table: true }
      )
    end

    def re_render_tags_chart(domain:, now: false)
      return if Util.env_is_true('DISABLE_CHART_UPDATE_STREAMS')
      stream_replace!(
        now: now,
        stream: "domain_#{domain.uid}_monitor_center_view_stream",
        target: "#{domain.uid}_domain_tags_chart",
        partial: 'charts/tags/index',
        locals: { 
          domain: domain, 
          chart_data: nil,
          displayed_metric: :tagsafe_score, 
          start_time: 1.day.ago, 
          end_time: Time.now
        }
      )
    end

    #################
    ## Tag streams ##
    #################

    def append_tag_row_to_table(tag:, now: false)
      stream_append!(
        now: now, 
        stream: "domain_#{tag.domain.uid}_monitor_center_view_stream",
        target: "#{tag.domain.uid}_domain_tags_table_rows", 
        partial: 'server_loadable_partials/tags/tag_table_row', 
        locals: { tag: tag, domain: tag.domain } 
      )
    end

    def update_tag_table_row(tag:, now: false)
      stream_replace!(
        now: now, 
        stream: "domain_#{tag.domain.uid}_monitor_center_view_stream", 
        target: "#{tag.domain.uid}_domain_tags_table_row_#{tag.uid}",
        partial: 'server_loadable_partials/tags/tag_table_row',
        locals: { tag: tag, domain: tag.domain }
      )
    end

    def update_tag_current_stats(tag:, now: false)
      stream_replace!(
        now: now, 
        stream: "tag_#{tag.uid}_details_view_stream",
        target: "tag_#{tag.uid}_current_stats",
        partial: 'tags/current_stats',
        locals: { tag: tag }
      )
    end
  
    def re_render_tag_chart(tag:, now: false)
      return if Util.env_is_true('DISABLE_CHART_UPDATE_STREAMS')
      # chart_data_getter = ChartHelper::TagData.new(tag: tag, metric: :tagsafe_score, start_time: 1.day.ago, end_time: Time.now)
      stream_replace!(
        now: now,
        stream: "tag_#{tag.uid}_details_view_stream",
        target: "#{tag.uid}_tag_chart",
        partial: 'charts/tags/show',
        locals: {
          tag: tag,
          chart_data: nil,
          chart_metric: :tagsafe_score,
          start_time: 1.day.ago,
          end_time: Time.now
        }
      )
    end
  
    def remove_tag_from_from_table(tag:, now: false)
      stream_remove!(now: now, stream: "domain_#{tag.domain.uid}_monitor_center_view_stream", target: "#{tag.domain.uid}_domain_tags_table_row_#{tag.uid}")
    end

    ########################
    ## TagVersion streams ##
    ########################

    def add_tag_version_to_tag_details_view(tag_version:,now: false)
      stream_prepend!(
        now: now, 
        stream: "tag_#{tag_version.tag.uid}_details_view_stream",
        target: "tag_#{tag_version.tag.uid}_tag_versions_table_rows",
        partial: 'server_loadable_partials/tag_versions/tag_version_row',
        locals: { tag_version: tag_version, tag: tag_version.tag }
      )
    end

    # def update_tag_version_table_row(tag_version:, now: false)
    #   stream_replace!(
    #     now: now, 
    #     stream: "tag_#{tag_version.tag.uid}_details_view_stream",
    #     target: "tag_version_#{tag_version.uid}_row",
    #     partial: 'server_loadable_partials/tag_versions/tag_version_row',
    #     locals: { tag_version: tag_version, tag: tag_version.tag }
    #   )
    # end

    ###################
    ## Audit streams ##
    ###################

    def prepend_audit_to_list(audit:, hide_primary_audit_indicator: true, now: false)
      stream_prepend!(
        now: now,
        stream: "tag_#{audit.tag.uid}_details_view_stream", 
        target: "tag_#{audit.tag.uid}_audits_table_rows",
        partial: 'audits/audit_row',
        locals: { audit: audit, hide_primary_audit_indicator: hide_primary_audit_indicator }
      )
      return if audit.run_on_live_tag?
      stream_prepend!(
        now: now,
        stream: "tag_version_#{audit.tag_version.uid}_audits_view_stream", 
        target: "tag_version_#{audit.tag_version.uid}_audits_table_rows",
        partial: 'audits/audit_row',
        locals: { audit: audit }
      )
    end

    def update_performance_audit_details_view(audit:, now: false)
      stream_replace!(
        now: now,
        stream: "audit_#{audit.uid}_details_view_stream",
        target: "audit_#{audit.uid}_performance_audit",
        partial: 'audits/performance_audit',
        locals: { audit: audit.reload, previous_audit: audit.audit_to_compare_with, tag: audit.tag }
      )
    end

    def update_performance_audit_progression_indicators(audit:, now: false)
      stream_replace!(
        now: now,
        stream: "audit_#{audit.uid}_details_view_stream",
        target: "audit_#{audit.uid}_performance_audit_progression_indicators",
        partial: "individual_performance_audits/progression_indicators",
        locals: { audit: audit }
      )
    end

    def update_audit_table_row(audit:, hide_primary_audit_indicator: true, now: false)
      stream_replace!(
        now: now,
        stream: "audit_#{audit.uid}_row_stream", 
        target: "audit_#{audit.uid}_row",
        partial: 'audits/audit_row',
        locals: { audit: audit, hide_primary_audit_indicator: hide_primary_audit_indicator }
      )
      # stream_replace!(
      #   now: now,
      #   stream: "tag_#{audit.tag.uid}_details_view_stream", 
      #   target: "audit_#{audit.uid}_row",
      #   partial: 'audits/audit_row',
      #   locals: { audit: audit }
      # )
      # return if audit.run_on_live_tag?
      # stream_replace!(
      #   now: now,
      #   stream: "tag_version_#{audit.tag_version.uid}_audits_view_stream", 
      #   target: "audit_#{audit.uid}_row",
      #   partial: 'audits/audit_row',
      #   locals: { audit: audit }
      # )
    end

    def re_render_audit_table(tag_version:, now: false)
      updated_audits_collection = tag_version.audits.order(primary: :DESC).most_recent_first.includes(:performance_audits).page(1).per(20)
      stream_replace!(
        now: now,
        stream: "tag_version_#{tag_version.uid}_audits_view_stream",
        target: "tag_version_#{tag_version.uid}_audits_table",
        partial: 'audits/audits_table',
        locals: { 
          audits: updated_audits_collection,
          tag_version: tag_version, 
          tag: tag_version.tag
        }
      )
    end

    #########################
    ## DomainAudit Streams ##
    #########################

    def stream_billing_details_updates(domain:, default_payment_method:)
      stream_replace!(
        now: true,
        stream: "domain_#{domain.uid}_billing_details_stream",
        target: "domain_#{domain.uid}_billing_details",
        partial: 'settings/billing_details',
        locals: { domain: domain, default_payment_method: default_payment_method }
      )
    end

    def update_domain_audit_details_view(domain_audit:, now: false)
      stream_replace!(
        now: now,
        stream: "domain_audit_#{domain_audit.uid}_details_stream",
        target: "domain_audit_#{domain_audit.uid}_details",
        partial: "domain_audits/show",
        locals: { domain_audit: domain_audit }
      )
    end

    def update_domain_audit_performance_impact_view(domain_audit:, now: false)
      if domain_audit.completed?
        average_delta_performance_audit = domain_audit.average_delta_performance_audit
        negative_metrics = NegativePerformanceAuditMetricsIdentifier.new(average_delta_performance_audit)
        stream_replace!(
          now: now,
          stream: "domain_audit_#{domain_audit.uid}_details_stream",
          target: "domain_audit_#{domain_audit.uid}_performance_impact",
          partial: "domain_audits/performance_impact",
          locals: { 
            domain_audit: domain_audit, 
            url_crawl: domain_audit.url_crawl,
            average_delta_performance_audit: average_delta_performance_audit,
            most_negative_performance_metric: negative_metrics.most_negative_performance_metric,
            negative_performance_metrics: negative_metrics.negative_performance_metrics
          }
        )
      else
        stream_replace!(
          now: now,
          stream: "domain_audit_#{domain_audit.uid}_details_stream",
          target: "domain_audit_#{domain_audit.uid}_performance_impact",
          partial: "domain_audits/performance_impact",
          locals: { 
            domain_audit: domain_audit, 
            url_crawl: domain_audit.url_crawl,
            average_delta_performance_audit: nil,
            most_negative_performance_metric: nil,
            negative_performance_metrics: []
          }
        )
      end
    end

    ############################
    ## FunctionalTest streams ##
    ############################

    def update_audit_test_run_row(test_run:, now: false)
      if test_run.is_a?(TestRunWithTag)
        stream_replace!(
          now: now,
          stream: "audit_#{test_run.audit&.uid}_test_runs_list_view",
          target: "test_run_#{test_run.uid}_row",
          partial: 'test_runs/test_run_row',
          locals: { 
            columns_to_exclude: ['Date', 'Type of Test'],
            test_run: test_run,
            column_width_percent: 100/3, 
            for_audit: true
          }
        )
      end
    end

    def update_functional_test_test_run_row(test_run:, now: false)
      # "functional_test_#{@functional_test.uid}_test_runs_list_view"
    end

    def update_test_run_details_view(test_run:, now: false)
      stream_replace!(
        now: now,
        stream: "test_run_#{test_run.uid}_details_view_stream",
        target: "test_run_#{test_run.uid}",
        partial: "test_runs/show",
        locals: { test_run: test_run }
      )
    end

    def update_audit_functional_tests_completion_indicator(audit:, now: false)
      stream_replace!(
        now: now,
        stream: "audit_#{audit.uid}_pending_functional_tests_pill_stream",
        target: "audit_#{audit.uid}_pending_functional_tests_pill",
        partial: "test_runs/pending_pill_for_audit",
        locals: { audit: audit }
      )
    end

    private

    def stream_replace!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals.merge(streamed: true))
    end

    def stream_append!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_append_to : :broadcast_append_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals.merge(streamed: true))
    end

    def stream_prepend!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_prepend_to : :broadcast_prepend_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals.merge(streamed: true))
    end

    def stream_remove!(now:, stream:, target:)
      send(:broadcast_remove_to, stream, target: target)
    end
  end
end