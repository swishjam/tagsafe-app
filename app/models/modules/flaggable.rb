module Flaggable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def object_flags
      ObjectFlag.where(object_id: id, object_type: self.class.to_s)
    end

    def flags
      Flag.joins(:object_flags).where(object_flags: { object_id: id, object_type: self.class.to_s })
    end

    def using_default_flag_for?(slug)
      flags.find_by(slug: slug).nil?
    end
  end
end