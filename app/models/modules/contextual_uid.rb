module ContextualUid
  UID_LENGTH = 8

  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods

    base.before_validation :set_uid, on: :create
    base.validates :uid, presence: true, uniqueness: true
  end

  module InstanceMethods
    def set_uid
      loop do
        custom_uid = "#{self.class.get_uid_prefix}_#{SecureRandom.hex(UID_LENGTH/2)}"
        unless self.class.find_by(uid: custom_uid)
          self.uid = custom_uid
          return
        else
          Rails.logger.warn "ContextualUid loop. Duplicate UID generated for #{self.class.to_s} model."
        end
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