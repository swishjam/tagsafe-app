module HasS3UrlColumn
  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods
  end
  
  class ClassMethods
    attr_reader :s3_columns

    def s3_url_column(column_name)
      self.s3_columns << column_name
    end

    private

    def define_instance_methods_for_column(column_name)
      # define_method
    end
  end
end