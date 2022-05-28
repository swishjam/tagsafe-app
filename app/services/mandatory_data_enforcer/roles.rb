module MandatoryDataEnforcer
  class Roles
    class << self
      
      def validate!
        create_roles_if_necessary
        Rails.logger.info "Validated all Roles present."
      end

      private
      
      def create_roles_if_necessary
        %w[user user_admin tagsafe_admin].each do |role|
          unless Role.find_by(name: role)
            puts "Creating #{role} Role."
            Role.create(name: role)
          end
        end
      end

    end
  end
end