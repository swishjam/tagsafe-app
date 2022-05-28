namespace :seed do
  task :mandatory_data => :environment do
    puts "Beginning seed."
    MandatoryDataEnforcer::Roles.validate!
    MandatoryDataEnforcer::UptimeRegions.validate!
    MandatoryDataEnforcer::ExecutionReasons.validate!
    MandatoryDataEnforcer::AwsEventBridgeRules.validate!
  end
end