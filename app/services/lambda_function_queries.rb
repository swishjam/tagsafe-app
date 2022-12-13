class LambdaFunctionQueries
  def self.uptime_check_query!(region_name:)


    sql = <<~SQL
      SELECT 
        domains.id AS domain_id,
        subscription_plans.status AS subscription_status,
        credit_wallet_for_current_month_and_year.credits_remaining AS remaining_credits,
        tags.id AS tag_id,
        tags.full_url AS tag_url, 
        uptime_regions.aws_name AS region,
        uptime_regions.id as uptime_region_id
      FROM 
        tags
        INNER JOIN domains
          ON domains.id=tags.domain_id
        INNER JOIN subscription_plans
          ON subscription_plans.id=domains.current_subscription_plan_id
        LEFT JOIN credit_wallets AS credit_wallet_for_current_month_and_year
          ON credit_wallet_for_current_month_and_year.domain_id=domains.id AND
          credit_wallet_for_current_month_and_year.month="#{Time.current.month}"
        INNER JOIN uptime_regions_to_check 
          ON uptime_regions_to_check.tag_id=tags.id
        INNER JOIN uptime_regions 
          ON uptime_regions.id=uptime_regions_to_check.uptime_region_id
      WHERE 
        uptime_regions.aws_name = "#{region_name}" AND
        subscription_plans.status NOT IN ("incomplete_expired", "unpaid") AND
        (
          credit_wallet_for_current_month_and_year.credits_remaining IS NULL OR 
          credit_wallet_for_current_month_and_year.credits_remaining > 0
        )
      GROUP BY
        domain_id,
        tag_id,
        tag_url, 
        region,
        uptime_region_id
    SQL
    ActiveRecord::Base.connection.execute(sql).entries
  end

  def self.release_check_query!(interval:)
    sql = <<~SQL
      SELECT 
        tags.id AS tag_id,
        tags.full_url AS tag_url, 
        live_tag_configurations.release_check_minute_interval AS release_check_minute_interval, 
        most_recent_tag_versions.hashed_content AS current_hashed_content,
        most_recent_tag_versions.bytes AS current_version_bytes_size,
        tags.marked_as_pending_tag_version_capture_at AS marked_as_pending_tag_version_capture_at,
        CASE
          WHEN tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring IS NULL
          THEN domain_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
          ELSE tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
        END AS num_recent_tag_versions_to_compare_in_release_monitoring
      FROM 
        tags
        INNER JOIN domains
          ON domains.id=tags.domain_id
        INNER JOIN tag_configurations AS live_tag_configurations 
          ON live_tag_configurations.tag_id=tags.id 
          AND live_tag_configurations.type = "LiveTagConfiguration"
        INNER JOIN tag_versions AS most_recent_tag_versions
          ON most_recent_tag_versions.id=tags.most_recent_tag_version_id
        LEFT JOIN general_configurations AS domain_general_configurations 
          ON domain_general_configurations.parent_type = "Domain" 
          AND domain_general_configurations.parent_id=tags.domain_id
        LEFT JOIN general_configurations AS tag_general_configurations 
          ON tag_general_configurations.parent_type = "Tag" 
          AND tag_general_configurations.parent_id=tags.id
      WHERE 
        live_tag_configurations.release_check_minute_interval = #{interval}
      GROUP BY
        tag_id,
        tag_url, 
        release_check_minute_interval, 
        current_hashed_content,
        current_version_bytes_size,
        num_recent_tag_versions_to_compare_in_release_monitoring,
        marked_as_pending_tag_version_capture_at
    SQL
    ActiveRecord::Base.connection.execute(sql).entries
  end
end