class AlertGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def create_model
    template('model.rb', File.join("app/models/alert_configurations/#{file_name}_alert_configuration.rb"))
    template('trigger_rules_serializer.rb', File.join("app/models/serializers/alert_trigger_rules/#{file_name}.rb"))
    template('mailer.rb', File.join("app/mailers/tagsafe_email/#{file_name}_alert.rb"))
    template('alert_evaluator.rb', File.join("app/services/alert_evaluators/#{file_name}.rb"))
  end
end
