module ContextualUid
  UID_LENGTH = 8

  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods
    base.before_create :set_uid
    base.implicit_order_column = "created_at"
  end

  module InstanceMethods
    def set_uid
      self.id = generate_uid
    end

    def generate_uid
      loop do
        custom_id = "#{self.class.get_uid_prefix}_#{SecureRandom.hex(UID_LENGTH/2)}"
        return custom_id unless self.class.find_by(id: custom_id)
      end
    end
  end

  module ClassMethods
    def uid_prefix(prefix)
      @uid_prefix = prefix
    end

    def get_uid_prefix
      @uid_prefix || default_uid_prefix
    end

    def default_uid_prefix
      self.to_s.split(/(?=[A-Z])/).collect{ |word| word[0].downcase }.join('')
    end
  end
end