class AddCustomIds < ActiveRecord::Migration[6.1]
  def change
    Dir["app/models/*.rb"].map do |file_path|
      require Rails.root.join(file_path)
    
      basename  = File.basename(file_path, File.extname(file_path))
      klass     = basename.camelize.constantize

      puts basename
      next if ['Notifier', 'ContextualUid', 'ApplicationRecord', 'TagCheckRegion'].include?(klass.to_s)
      table_name = klass.table_name
    
      change_column table_name, :id, :string
      if column_exists?(table_name, :uid)
        remove_column table_name, :uid
      end
      if column_exists?(table_name, :tagsafe_id)
        remove_column table_name, :tagsafe_id
      end

      klass.columns.each do |column|
        if column.name.ends_with? '_id'
          puts "Updating #{table_name} #{column.name} to string"
          change_column table_name, column.name, :string
        end
      end
    end
  end
end
