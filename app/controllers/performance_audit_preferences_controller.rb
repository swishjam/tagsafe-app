class PerformanceAuditPreferencesController < LoggedInController
  def update
    preferences = PerformanceAuditPreference.find(params[:id])
    preferences.update(preferences_params)
    display_toast_message("Updated performance audit preferences for #{preferences.script_subscriber.try_friendly_name}")
    redirect_to request.referrer
  end

  def preferences_params
    params.require(:performance_audit_preference).permit(:num_test_iterations, :url_to_audit)
  end
end