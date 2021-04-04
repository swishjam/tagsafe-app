class AuditCompletedSlackNotification < SlackNotificationSubscriber
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper

  def friendly_name
    'On Completed Audits'
  end

  def notify!(audit)
    slack_client.notify!(channel: channel, blocks: blocks(audit))
  end

  def blocks(audit)
    block = [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*#{audit.tag.try_friendly_name} audit has completed.*"
        },
        "accessory": {
          "type": "image",
          "image_url": "#{audit.tag.try_image_url}",
          "alt_text": "Tag image"
        }
      }
    ]

    add_metrics_to_block(audit, block)
    add_buttons_to_block(audit, block)
  end

  def add_metrics_to_block(audit, block)
    add_metric_to_block(audit, block, :com_complete, 'DOM Complete')
    add_metric_to_block(audit, block, :dom_interactive, 'DOM Interactive')
    add_metric_to_block(audit, block, :first_contentful_paint, 'First Contentful Paint')
    add_metric_to_block(audit, block, :script_duration, 'Script Duration')
    add_metric_to_block(audit, block, :layout_duration, 'Layout Duration')
    add_metric_to_block(audit, block, :task_duration, 'Task Duration')
  end

  def add_metric_to_block(audit, block, key, title)
    block << performance_metric_fields(audit, title, key)
  end

  def performance_metric_fields(audit, title, metric_key)
    impact = audit.delta_performance_audit.send(metric_key)
    difference = audit.delta_performance_audit.change_in_metric(metric_key)
    percent_difference = audit.delta_performance_audit.percent_change_in_metric(metric_key)
    impact_text = impact.positive? ? ":heavy_plus_sign: #{number_to_human(impact, units: { unit: 'ms', thousand: 'seconds' })}\n" : "No Impact\n"
    change_text = case
                  when difference.zero?
                    then 'No Change'
                  when difference.positive?
                    then ":arrow_up: #{number_to_human(difference.round(2), units: { unit: 'ms', thousand: 'seconds' })} (#{number_with_delimiter percent_difference.round(2)}%)"
                  when difference.negative?
                    then ":arrow_down: #{number_to_human(difference.round(2), units: { unit: 'ms', thousand: 'seconds' })} (#{number_with_delimiter percent_difference.round(2)}%)"
                  end
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*#{title} Impact:*\n#{impact_text}"
        },
        {
          "type": "mrkdwn",
          "text": "*#{title} Impact Change:*\n#{change_text}"
        }
      ]
    }    
  end

  def add_buttons_to_block(audit, block)
    block << {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "emoji": true,
            "text": "View Audit"
          },
          "url": "#{tag_tag_version_audit_url(audit.tag, audit.tag_version, audit, host: ENV['CURRENT_HOST'])}",
          "style": "primary",
          "value": "view_audit"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "emoji": true,
            "text": "Tag Details"
          },
          "url": "#{tag_url(audit.tag, audit, host: ENV['CURRENT_HOST'])}",
          "value": "view_tag_details"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "emoji": true,
            "text": "Monitor Center"
          },
          "url": "#{scripts_url(host: ENV['CURRENT_HOST'])}",
          "value": "monitor_center"
        }
      ]
    }
  end
end