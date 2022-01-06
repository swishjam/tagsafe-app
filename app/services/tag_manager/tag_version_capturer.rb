module TagManager
  class TagVersionCapturer
    def initialize(tag, content, hashed_content: nil)
      @tag = tag
      @content = content
      @hashed_content = hashed_content || TagManager::Hasher.hash!(@content)
    end

    def capture_new_tag_version!
      tag_version = @tag.tag_versions.create!(tag_version_data)
      tag_version.js_file.attach(tag_version_js_file_data)
      tag_version.formatted_js_file.attach(tag_version_formatted_js_file_data)
      remove_temp_files
    end

    private

    def tag_version_data
      {
        hashed_content: @hashed_content,
        bytes: @content.bytesize
      }
    end

    def tag_version_js_file_data
      { 
        io: File.open(js_file), 
        filename: db_filename(:compiled),
        content_type: 'text/javascript'
      }
    end

    def tag_version_formatted_js_file_data
      { 
        io: File.open(formatted_js_file), 
        filename: db_filename(:formatted),
        content_type: 'text/javascript'
      }
    end

    def js_file
      @js_file ||= write_content_to_file(@content, local_file_location(:compiled))
    end

    def formatted_js_file
      return @formatted_js_file if @formatted_js_file
      TagManager::JsBeautifier.new(
        read_file: local_file_location(:compiled), 
        output_file: local_file_location(:formatted)
      ).beautify!
      @formatted_js_file = File.open(local_file_location(:formatted))
      @formatted_js_file.close
      @formatted_js_file
    end

    def write_content_to_file(content, local_filename)
      file = File.open(local_filename, "w") 
      file.puts content.force_encoding('UTF-8')
      file.close
      file
    end

    def db_filename(suffix)
      "#{@tag.try_friendly_slug}-#{@hashed_content.slice(0, 8)}-#{Time.current.to_i}-#{suffix}.js"
    end

    def local_file_location(suffix)
      "#{Util.create_dir_if_neccessary(Rails.root, 
                                        'tmp',
                                        'tag_versions',
                                        Time.now.month.to_s, 
                                        Time.now.day.to_s,
                                        @tag.id.to_s)}/#{@hashed_content}-#{suffix}.js"
    end

    def remove_temp_files
      File.delete(local_file_location(:compiled))
      File.delete(local_file_location(:formatted))
    end
  end
end