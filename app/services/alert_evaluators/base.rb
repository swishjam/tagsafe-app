module AlertEvaluators
  class Base
    def self.alert_configuration_klass
      "#{self.to_s.split('::')[1]}AlertConfiguration".constantize
    end

    def alert_configurations_for_tag_and_domain
      @alert_configurations_for_tag_and_domain ||= begin
        alert_configs_for_tag = @tag.alert_configurations.active.not_enabled_for_all_tags.by_klass(self.class.alert_configuration_klass)
        alert_configs_for_domain = @tag.domain.alert_configurations.active.enabled_for_all_tags.by_klass(self.class.alert_configuration_klass)
        alert_configs_for_tag.to_a.concat(alert_configs_for_domain.to_a)
      end
    end
  end
end