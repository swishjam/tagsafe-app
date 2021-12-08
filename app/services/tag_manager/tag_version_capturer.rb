module TagManager
  class TagVersionCapturer
    def initialize(tag, content, hashed_content: nil, keep_file_on_disk: ENV['KEEP_TAG_VERSIONS_ON_DISK'] == 'true')
      @tag = tag
      @content = content
      @hashed_content = hashed_content
      @keep_file_on_disk = keep_file_on_disk
    end

    def capture_new_tag_version!
      tag_version = @tag.tag_versions.create!(tag_version_data)
      tag_version.js_file.attach(tag_version_js_file_data)
      tag_version.tagsafe_instrumented_js_file.attach(tagsafe_instrumented_js_file_data)
      remove_temp_files unless @keep_file_on_disk
    end

    private

    def tag_version_data
      {
        hashed_content: @hashed_content || TagManager::Hasher.hash!(@content),
        bytes: @content.bytesize
      }
    end

    def tag_version_js_file_data
      { 
        io: File.open(js_file), 
        filename: db_filename(:verbatim),
        content_type: 'text/javascript'
      }
    end

    def tagsafe_instrumented_js_file_data
      {
        io: File.open(tagsafe_instrumented_js_file),
        filename: db_filename(:instrumented),
        content_type: 'text/javascript'
      }
    end

    def js_file
      @js_file ||= write_content_to_file(@content, local_file_location(:verbatim))
    end

    def tagsafe_instrumented_js_file
      @tagsafe_instrumented_js_file ||= write_content_to_file(tagsafe_instrumented_content, local_file_location(:instrumented))
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
                                        'public',
                                        'tag_versions',
                                        Time.now.month.to_s, 
                                        Time.now.day.to_s,
                                        @tag.id.to_s)}/#{@hashed_content}-#{suffix}.js"
    end

    def remove_temp_files
      File.delete(local_file_location(:verbatim))
      File.delete(local_file_location(:instrumented))
    end

    def tagsafe_instrumented_content
      @content << ';' if @content.strip.last != ';'
      <<-JS
        (function(){
          window.performance.mark("tagsafeExecutionStart");
        })();
        #{@content}
        (function(){ 
          window.performance.mark("tagsafeExecutionEnd"); 
          window.performance.measure("tagsafeExecutionTime", "tagsafeExecutionStart", "tagsafeExecutionEnd");
          console.log(`Tagsafe execution time: ${window.performance.getEntriesByName('tagsafeExecutionTime')[0].duration} ms.`);
        })();
      JS
    end
  end
end