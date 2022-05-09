module ContextualUid
  UID_LENGTH = (ENV['CONTEXTUAL_UID_LENGTH'] || 8).to_i
  @@prefix_model_dictionary = {}

  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods

    base.before_validation :set_uid, on: :create
    base.validates :uid, on: :create, presence: true, uniqueness: true, unless: -> { self.class.should_skip_contextual_uid? }
    # validate_and_store_klass_and_subclasses_uid_prefixes(base)
  end

  def self.validate_and_store_klass_and_subclasses_uid_prefixes(klass)
    store_to_prefix_model_dictionary!(klass) unless klass.table_name.nil?
    klass.subclasses.each do |subclass|
      validate_and_store_klass_and_subclasses_to_prefix_dictionary(subclass)
    end
  end

  def self.store_to_prefix_model_dictionary!(klass)
    if @@prefix_model_dictionary[klass.get_uid_prefix]
      raise StandardError, "Duplicate Contextual UID prefixes, #{klass.to_s} and #{@prefix_model_dictionary[klass.get_uid_prefix].to_s} both use #{klass.get_uid_prefix}"
    end
    @@prefix_model_dictionary[klass.get_uid_prefix] = klass.to_s
  end

  def self.find_object_by_uid(uid)
    uid_prefix = uid.split('_')[0]
    @@prefix_model_dictionary[uid_prefix].constantize.find_by(uid: uid)
  end

  module InstanceMethods
    def set_uid
      unless self.class.should_skip_contextual_uid?
        loop do
          custom_uid = "#{self.class.get_uid_prefix}_#{SecureRandom.hex(UID_LENGTH/2)}"
          unless self.class.find_by(uid: custom_uid)
            self.uid = custom_uid
            return
          else
            Rails.logger.warn "ContextualUid loop. Duplicate UID generated for #{self.class.to_s} model (#{custom_uid})."
          end
        end
      end
    end
  end

  module ClassMethods
    def skip_contextual_uid
      @@should_skip_contextual_uid = true
    end

    def should_skip_contextual_uid?
      defined?(@@should_skip_contextual_uid) && @@should_skip_contextual_uid == true
    end

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