module TagManager
  class TagVersionCapturer
    def initialize(tag:, content:, release_check:)
      @tag = tag
      @original_content = content
      @release_check = release_check
      
      @minifier = TagsafeMinifier.new(@original_content)
      @minifier.minified_content
    end

    def capture_new_tag_version!
      tag_version = @tag.tag_versions.create!(tag_version_data)
      upload_files_to_s3!(tag_version)
      Rails.logger.info "TagVersionCapturer - captured new TagVersion after #{Time.now - @tag.marked_as_pending_tag_version_capture_at} seconds from when it was detected." if @tag.marked_as_pending_tag_version_capture_at.present?
      @tag.update!(marked_as_pending_tag_version_capture_at: nil, most_recent_tag_version: tag_version)
      @tag.update!(current_live_tag_version: tag_version) if @tag.current_live_tag_version.nil?
      remove_temp_files
      tag_version
    end

    private

    def tag_version_data
      {
        hashed_content: Digest::MD5.hexdigest(@original_content),
         # what's written to file seems to be slightly different than the @original_content in memory?
        sha_256: OpenSSL::Digest.new('SHA256').base64digest( File.read(js_file) ),
        sha_512: OpenSSL::Digest.new('SHA512').base64digest( File.read(js_file) ),
        bytes: @original_content.bytesize,
        original_content_byte_size: @original_content.bytesize,
        tagsafe_minified_byte_size: @minifier.minified_successfully? ? @minifier.minified_content.bytesize : -1,
        release_check_captured_with: @release_check,
        commit_message: TagManager::CommitMessageParser.try_to_get_commit_message(@original_content),
        num_additions: num_additions,
        num_deletions: num_deletions,
        total_changes: total_changes
      }
    end

    def upload_files_to_s3!(tag_version)
      upload_file_to_s3(js_file, tag_version)
      upload_file_to_s3(formatted_js_file, tag_version, true)
    end

    def upload_file_to_s3(file, tag_version, is_formatted = false)
      TagsafeAws::S3.write_to_s3(
        bucket: "tagsafe-#{Rails.env}-tag-versions", 
        key: tag_version.s3_pathname(formatted: is_formatted, strip_leading_slash: true),
        content: File.read(file),
        cache_control: 'public, immutable, max-age=31536000, stale-while-revalidate=86400', # cache for 1 year
        acl: 'public-read',
        content_type: 'text/javascript'
      )
    end

    def num_additions
      return nil if @tag.has_no_versions?
      diff_analyzer.num_additions
    end

    def num_deletions
      return nil if @tag.has_no_versions?
      diff_analyzer.num_deletions
    end

    def total_changes
      return nil if @tag.has_no_versions?
      num_additions + num_deletions
    end

    def diff_analyzer
      @diff_analyzer ||= DiffAnalyzer.new(
        new_content: File.read(formatted_js_file),
        previous_content: @tag.most_recent_tag_version.content(formatted: true),
        num_lines_of_context: 0,
        include_diff_info: false
      )
    end

    def js_file
      return @js_file if @js_file
      @js_file = File.open(local_file_location(:compiled), "w") 
      @js_file.puts @minifier.minified_content.force_encoding('UTF-8')
      @js_file.close
      @js_file
    end

    def formatted_js_file
      return @formatted_js_file if @formatted_js_file
      @formatted_js_file = File.open(local_file_location(:formatted), 'w')
      formatted_js_content = TagManager::JsBeautifier.beautify_string!(@original_content)
      @formatted_js_file.puts formatted_js_content.force_encoding('UTF-8')
      @formatted_js_file.close
      @formatted_js_file
    end

    def local_file_location(suffix)
      "#{Util.create_dir_if_neccessary(Rails.root, 
                                        'tmp',
                                        'tag_versions',
                                        Time.now.month.to_s, 
                                        Time.now.day.to_s,
                                        @tag.id.to_s)}/#{Digest::MD5.hexdigest(@original_content)}-#{suffix}.js"
    end

    def remove_temp_files
      File.delete(local_file_location(:compiled))
      File.delete(local_file_location(:formatted))
    end
  end
end