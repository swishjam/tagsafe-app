module Streamable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    ####################
    ## Domain streams ##
    ####################

    # really should just be used after the first Tag is created during onboarding
    def re_render_tags_table(domain:, empty: false, now: false)
      stream_replace!(
        now: now,
        stream: "domain_#{domain.uid}_monitor_center_view_stream",
        target: "#{domain.uid}_domain_tags_table",
        partial: 'server_loadable_partials/tags/tag_table',
        locals: { domain: self, tags: empty ? [] : domain.tags.page(1).per(9), allow_empty_table: true }
      )
    end

    def re_render_tags_chart(domain:, now: false)
      return if ENV['DISABLE_CHART_UPDATE_STREAMS'] == 'true'
      stream_replace!(
        now: now,
        stream: "domain_#{domain.uid}_monitor_center_view_stream",
        target: "#{domain.uid}_domain_tags_chart",
        partial: 'charts/tags',
        locals: { 
          domain: domain, 
          chart_data: nil,
          displayed_metric: :tagsafe_score, 
          start_time: 1.day.ago, 
          end_time: Time.now, 
          streamed: true 
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
        locals: { tag: tag, domain: tag.domain, streamed: true } 
      )
    end

    def update_tag_table_row(tag:, now: false)
      stream_replace!(
        now: now, 
        stream: "domain_#{tag.domain.uid}_monitor_center_view_stream", 
        target: "#{tag.domain.uid}_domain_tags_table_row_#{tag.uid}",
        partial: 'server_loadable_partials/tags/tag_table_row',
        locals: { tag: tag, domain: tag.domain, streamed: true }
      )
    end

    def update_tag_current_stats(tag:, now: false)
      stream_replace!(
        now: now, 
        stream: "tag_#{tag.uid}_details_view_stream",
        target: "tag_#{tag.uid}_current_stats",
        partial: 'tags/current_stats',
        locals: { tag: tag, streamed: true }
      )
    end
  
    def re_render_tag_chart(tag:, now: false)
      return if ENV['DISABLE_CHART_UPDATE_STREAMS'] == 'true'
      # chart_data_getter = ChartHelper::TagData.new(tag: tag, metric: :tagsafe_score, start_time: 1.day.ago, end_time: Time.now)
      stream_replace!(
        now: now,
        stream: "tag_#{tag.uid}_details_view_stream",
        target: "#{tag.uid}_tag_chart",
        partial: 'charts/tag',
        locals: {
          chart_data: nil,
          chart_metric: :tagsafe_score,
          start_time: 1.day.ago,
          end_time: Time.now,
          streamed: true
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
        locals: { tag_version: tag_version, tag: tag_version.tag, streamed: true }
      )
    end

    # def update_primary_audit_pill_for_tag_version(tag_version:, now: false)
    #   stream_replace!(
    #     now: now, 
    #     stream: "domain_#{tag_version.tag.domain.uid}_monitor_center_view_stream", 
    #     target: "tag_version_#{tag_version.uid}_primary_audit_pill", 
    #     partial: 'audits/primary_audit_for_tag_version_pill',
    #     locals: { tag_version: tag_version, tag: tag_version.tag, streamed: true }
    #   )
    # end

    def update_tag_version_table_row(tag_version:, now: false)
      stream_replace!(
        now: now, 
        stream: "tag_#{tag_version.tag.uid}_details_view_stream",
        target: "tag_version_#{tag_version.uid}_row",
        partial: 'server_loadable_partials/tag_versions/tag_version_row',
        locals: { tag_version: tag_version, tag: tag_version.tag, streamed: true }
      )
    end

    ###################
    ## Audit streams ##
    ###################

    def prepend_audit_to_list(audit:, now: false)
      stream_prepend!(
        now: now,
        stream: "tag_version_#{audit.tag_version.uid}_audits_view_stream", 
        target: "tag_version_#{audit.tag_version.uid}_audits_table_rows",
        partial: 'audits/audit_row',
        locals: { audit: audit, streamed: true }
      )
    end

    def update_audit_details_view(audit:, now: false)
      stream_replace!(
        now: now,
        stream: "audit_#{audit.uid}_details_view_stream",
        target: "audit_#{audit.uid}",
        partial: 'audits/show',
        locals: { audit: self, previous_audit: audit.tag_version.previous_version&.primary_audit, tag: audit.tag, tag_version: audit.tag_version, streamed: true }
      )
    end

    def update_audit_table_row(audit:, now: false)
      stream_replace!(
        now: now,
        stream: "tag_version_#{audit.tag_version.uid}_audits_view_stream", 
        target: "audit_#{audit.uid}_row",
        partial: 'audits/audit_row',
        locals: { audit: audit, streamed: true }
      )
    end

    def re_render_audit_table(audit:, now: false)
      # updated_audits_collection = audit.tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
      stream_replace!(
        now: now,
        stream: "tag_version_#{audit.tag_version.uid}_audits_view_stream",
        target: "tag_version_#{audit.tag_version.uid}_audits_table",
        partial: 'audits/audits_table',
        locals: { tag_version: audit.tag_version, streamed: true }
      )
    end

    ############################
    ## FunctionalTest streams ##
    ############################


    # broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    # partial = if failed?
    #             'test_runs/show_failed'
    #           elsif pending?
    #             'test_runs/show_pending'
    #           elsif passed?
    #             'test_runs/show_passed'
    #           end
    # stream_replace!(
    #   now: now,
    #   stream: "new_functional_test_view_stream",
    #   target: "test_run_#{uid}",
    #   partial: partial,
    #   locals: { functional_test: functional_test, test_run: self, streamed: true }
    # )
    # send(broadcast_method,
    #   "functional_test_#{functional_test.uid}_show_view_stream",
    #   target: "test_run_#{uid}",
    #   partial: partial,
    #   locals: { functional_test: functional_test, test_run: self, streamed: true }
    # )

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
            for_audit: true,
            streamed: true
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
        locals: {
          test_run: test_run,
          streamed: true
        }
      )
    end

    private

    def stream_replace!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals)
    end

    def stream_append!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_append_to : :broadcast_append_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals)
    end

    def stream_prepend!(now:, stream:, target:, partial:, locals: {})
      broadcast_method = now ? :broadcast_prepend_to : :broadcast_prepend_later_to
      send(broadcast_method, stream, target: target, partial: partial, locals: locals)
    end

    def stream_remove!(now:, stream:, target:)
      broadcast_method = now ? :broadcast_remove_to : :broadcast_remove_later_to
      send(broadcast_method, stream, target: target)
    end
  end
end