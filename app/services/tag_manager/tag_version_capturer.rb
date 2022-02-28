module TagManager
  class TagVersionCapturer
    def initialize(tag:, content:, tag_check:, hashed_content:)
      @tag = tag
      @content = content
      @tag_check = tag_check
      @hashed_content = hashed_content
    end

    def capture_new_tag_version!
      if @content.nil?
        msg = "TagVersionCapturer `capture_new_tag_version!` called with @content = nil for Tag #{@tag.uid}"
        Rails.logger.error msg
        Sentry.capture_message(msg)
        return
      end
      tag_version = @tag.tag_versions.create!(tag_version_data)
      tag_version.js_file.attach(tag_version_js_file_data)
      tag_version.formatted_js_file.attach(tag_version_formatted_js_file_data)
      remove_temp_files
      tag_version
    end

    private

    def tag_version_data
      {
        hashed_content: @hashed_content,
        bytes: @content.bytesize,
        tag_check_captured_with: @tag_check
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
      return @js_file if @js_file
      @js_file = File.open(local_file_location(:compiled), "w") 
      @js_file.puts @content.force_encoding('UTF-8')
      @js_file.close
      @js_file
    end

    def formatted_js_file
      return @formatted_js_file if @formatted_js_file
      @formatted_js_file = TagManager::JsBeautifier.new(
        read_file: local_file_location(:compiled), 
        output_file: local_file_location(:formatted)
      ).beautify!
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