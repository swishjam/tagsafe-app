class ChartsController < ApplicationController
  def script_changes
    domain = Domain.find(params[:domain_id])
    chart_data = []
    domain.script_subscriptions.active.includes(script: [:script_changes]).each do |script_subscriber|
      script_change_data = {}
      script_subscriber.script.script_changes.each do |script_change|
        primary_audit = script_subscriber.primary_audit_by_script_change(script_change)
        unless primary_audit.nil?
          script_change_data[script_change.created_at] = primary_audit.delta_lighthouse_audit.formatted_performance_score
        end
      end
      chart_data << { name: script_subscriber.try_friendly_name, data: script_change_data }
    end
    render json: chart_data
  end
end