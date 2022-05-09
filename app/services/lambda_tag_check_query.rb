class LambdaReleaseCheckQuery
  def self.run_query!(interval:, region:)
    sql = <<~SQL
      SELECT
        tags.id AS tag_id,
        tags.full_url AS tag_url, 
        tag_preferences.release_check_minute_interval AS release_check_minute_interval, 
        uptime_regions.aws_name AS region,
        current_tag_versions.hashed_content AS current_hashed_content,
        current_tag_versions.bytes AS current_version_bytes_size,
        CASE
          WHEN tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring IS NULL
          THEN domain_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
          ELSE tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
        END AS num_recent_tag_versions_to_compare_in_release_monitoring,
        JSON_ARRAY(GROUP_CONCAT(ten_most_recent_tag_versions.hashed_content)) AS ten_most_recent_hashed_content
      FROM 
        tags
        INNER JOIN uptime_regions_to_check 
          ON uptime_regions_to_check.tag_id=tags.id
        INNER JOIN uptime_regions 
          ON uptime_regions.id=uptime_regions_to_check.uptime_region_id
        INNER JOIN tag_preferences 
          ON tag_preferences.tag_id=tags.id
        LEFT JOIN general_configurations 
          AS domain_general_configurations 
          ON domain_general_configurations.parent_type = "Domain" 
          AND domain_general_configurations.parent_id=tags.domain_id
        LEFT JOIN general_configurations 
          AS tag_general_configurations 
          ON tag_general_configurations.parent_type = "Tag" 
          AND tag_general_configurations.parent_id=tags.id
        LEFT JOIN tag_versions 
          AS current_tag_versions 
          ON current_tag_versions.tag_id=tags.id 
          AND current_tag_versions.most_recent = true
        LEFT JOIN LATERAL (
            SELECT * 
            FROM tag_versions
            WHERE tag_versions.tag_id = tags.id
            ORDER BY tag_versions.created_at ASC
            LIMIT 10
          ) AS ten_most_recent_tag_versions
          ON ten_most_recent_tag_versions.tag_id=tags.id
      WHERE 
        tag_preferences.release_check_minute_interval = #{interval} 
        AND uptime_regions.aws_name = "#{region}"
        AND tags.marked_as_pending_tag_version_capture_at IS NULL
      GROUP BY
        tag_id,
        tag_url, 
        release_check_minute_interval, 
        region,
        current_hashed_content,
        current_version_bytes_size,
        num_recent_tag_versions_to_compare_in_release_monitoring
    SQL
    ActiveRecord::Base.connection.execute(sql).entries
  end
end