module TagManager
  class ChangeProcessor
    def initialize(tag, content, hashed_content: nil, keep_file_on_disk: ENV['KEEP_TAG_VERSIONS_ON_DISK'] == 'true')
      @tag = tag
      @content = content
      @hashed_content = hashed_content
      @keep_file_on_disk = keep_file_on_disk
    end

    def process_change!
      @tag.tag_versions.create!(formatted_data)
      remove_temp_file unless @keep_file_on_disk
    end

    def update_tag_version!(tag_version)
      tag_version.update!(formatted_data)
      remove_temp_file unless @keep_file_on_disk
    end

    private

    def formatted_data
      {
        hashed_content: @hashed_content || TagManager::Hasher.hash!(@content),
        bytes: @content.bytesize,
        js_file: { io: File.open(js_file), filename: filename }
      }
    end

    def js_file
      @js_file ||= write_content_to_file
    end

    def write_content_to_file
      unless @js_file
        @js_file = File.open(written_file_location, "w") 
        @js_file.puts @content.force_encoding('UTF-8')
        @js_file.close
      end
      @js_file
    end

    def filename
      "#{@tag.try_friendly_slug}-#{@hashed_content.slice(0, 8)}-#{Time.current.to_i}.js"
    end

    def written_file_location
      "#{Util.create_dir_if_neccessary(Rails.root, 
                                        'public',
                                        'tag_versions',
                                        Time.now.month.to_s, 
                                        Time.now.day.to_s,
                                        @tag.id.to_s)}/#{@hashed_content}.js"
    end

    def remove_temp_file
      File.delete(written_file_location)
    end
  end
end