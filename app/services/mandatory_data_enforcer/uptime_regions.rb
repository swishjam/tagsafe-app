module MandatoryDataEnforcer
  class UptimeRegions
    class << self
      REGION_DICT = {
        'us-east-1' => 'US East (N. Virginia)',
        'us-east-2' => 'US East (Ohio)',
        'us-west-1' => 'US West (N. California)',
        'us-west-2' => 'US West (Oregon)',
        'af-south-1' => 'Africa (Cape Town)',
        'ap-east-1' => 'Asia Pacific (Hong Kong)',
        'ap-southeast-3' => 'Asia Pacific (Jakarta)',
        'ap-south-1' => 'Asia Pacific (Mumbai)',
        'ap-northeast-3' => 'Asia Pacific (Osaka)',
        'ap-northeast-2' => 'Asia Pacific (Seoul)',
        'ap-southeast-1' => 'Asia Pacific (Singapore)',
        'ap-southeast-2' => 'Asia Pacific (Sydney)',
        'ap-northeast-1' => 'Asia Pacific (Tokyo)',
        'ca-central-1' => 'Canada (Central)',
        'cn-north-1' => 'China (Beijing)',
        'cn-northwest-1' => 'China (Ningxia)',
        'eu-central-1' => 'Europe (Frankfurt)',
        'eu-west-1' => 'Europe (Ireland)',
        'eu-west-2' => 'Europe (London)',
        'eu-south-1' => 'Europe (Milan)',
        'eu-west-3' => 'Europe (Paris)',
        'eu-north-1' => 'Europe (Stockholm)',
        'me-south-1' => 'Middle East (Bahrain)',
        'sa-east-1' => 'South America (São Paulo)'
      }
      
      def validate!(update_existing: false)
        create_uptime_regions_if_necessary(update_existing)
        Rails.logger.info "Validated all UptimeRegions present."
      end
  
      private
  
      def create_uptime_regions_if_necessary(update_existing)
        REGION_DICT.each do |aws_name, location|
          existing = UptimeRegion.find_by(aws_name: aws_name)
          if existing.present?
            next unless update_existing
            puts "Updating #{aws_name} UptimeRegion"
            existing.update!(aws_name: aws_name, location: location)
          else
            puts "Creating new #{aws_name} UptimeRegion"
            UptimeRegion.create!(aws_name: aws_name, location: location)
          end
        end
      end
    end

  end
end