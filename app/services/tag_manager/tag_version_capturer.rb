module TagManager
  class TagVersionCapturer
    def initialize(tag:, content:, release_check:, hashed_content:, bytes:)
      @tag = tag
      @content = content
      @release_check = release_check
      @hashed_content = hashed_content
      @bytes = bytes
    end

    def capture_new_tag_version!
      tag_version = @tag.tag_versions.create!(tag_version_data)
      upload_files_to_s3!(tag_version)
      Rails.logger.info "TagVersionCapturer - captured new TagVersion after #{Time.now - @tag.marked_as_pending_tag_version_capture_at} seconds from when it was detected." if @tag.marked_as_pending_tag_version_capture_at.present?
      @tag.update!(
        marked_as_pending_tag_version_capture_at: nil, 
        current_live_tag_version: tag_version, # eventually this should move to after we run our audits and is verified to be safe
        most_recent_tag_version: tag_version
      )
      remove_temp_files
      tag_version
    end

    private

    def tag_version_data
      {
        hashed_content: @hashed_content,
         # what's written to file seems to be slightly different than the @content in memory?
        sha_256: OpenSSL::Digest.new('SHA256').base64digest( File.read(js_file) ),
        # sha_512: OpenSSL::Digest.new('SHA512').base64digest(File.read(tag_version_js_file[:io]),
        bytes: @bytes,
        release_check_captured_with: @release_check,
        commit_message: TagManager::CommitMessageParser.new(@content).try_to_get_commit_message,
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
        new_content: File.read(js_file),
        previous_content: @tag.current_version.content(formatted: true),
        num_lines_of_context: 0,
        include_diff_info: false
      )
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