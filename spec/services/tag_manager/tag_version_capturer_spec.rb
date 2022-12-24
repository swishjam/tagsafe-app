require 'rails_helper'

RSpec.describe TagsafeInstrumentationManager::InstrumentationConfigGenerator do
  before(:each) do
    prepare_test!
    @tag = create_tag_with_associations
    release_check_batch = create(:release_check_batch)
    @release_check = create(
      :release_check, 
      release_check_batch: release_check_batch, 
      tag: @tag,
      captured_new_tag_version: true, 
      hash_changed: true,
    )

    stub_http_requests_to(/https:\/\/cdn-collin-dev.tagsafe.io\/tags\/#{@container.instrumentation_key}\/#{@tag.hostname_and_path.gsub('.', '_').gsub("\/", '_')}-tv_*/)
  end

  describe '#capture_new_tag_version!' do
    it 'captures a new TagVersion' do
      expect(@tag.tag_versions.count).to be(1)
      new_tag_version = TagManager::TagVersionCapturer.new(tag: @tag, content: "function someFunctionName() {\n console.log('bar');\n }", release_check: @release_check).capture_new_tag_version!
      expect(@tag.tag_versions.count).to be(2)
    end

    it 'sets the tagsafe_minified_byte_size to -1 if it wasn\'t successfully minified' do
      allow_any_instance_of(TagManager::TagsafeMinifier).to receive(:minified_successfully?).and_return(false)
      js_content = "function someFunctionName() {\n console.log('bar');\n }"
      new_tag_version = TagManager::TagVersionCapturer.new(tag: @tag, content: js_content, release_check: @release_check).capture_new_tag_version!
      expect(new_tag_version.tagsafe_minified_byte_size).to be(-1)
      expect(new_tag_version.original_content_byte_size).to be(js_content.bytesize)
    end

    it "creates the TagVersion with the correct `hashed_content`, `sha_256`, and `sha_512` values" do
      js_content = "function someFunctionName() {\n console.log('bar');\n }"
      capturer = TagManager::TagVersionCapturer.new(tag: @tag, content: js_content, release_check: @release_check)
      js_file_content =  File.read(capturer.send(:js_file))
      new_tag_version = capturer.capture_new_tag_version!

      expect(new_tag_version.hashed_content).to eq(Digest::MD5.hexdigest(js_content))
      expect(new_tag_version.sha_256).to eq(OpenSSL::Digest.new('SHA256').base64digest(js_file_content))
      expect(new_tag_version.sha_512).to eq(OpenSSL::Digest.new('SHA512').base64digest(js_file_content))
    end

    it "uploads the formatted and compiled TagVersion content to s3" do      
      capturer = TagManager::TagVersionCapturer.new(tag: @tag, content: "function someFunctionName() {\n console.log('bar');\n }", release_check: @release_check)
      expect(capturer).to receive(:upload_files_to_s3!).exactly(:once)
      capturer.capture_new_tag_version!
    end
  end

  describe '#upload_to_s3!' do
    it 'calls the TagsafeAws::S3 class with the correct arguments' do
      js_content = "function someFunctionName() {\n console.log('bar');\n }"
      capturer = TagManager::TagVersionCapturer.new(tag: @tag, content: js_content, release_check: @release_check)
      tag_version = @tag.tag_versions.create!( capturer.send(:tag_version_data) )

      allow(tag_version).to receive(:s3_pathname).with(formatted: true, strip_leading_slash: true).and_return('tag-versions-s3-formatted-pathname')
      allow(tag_version).to receive(:s3_pathname).with(formatted: false, strip_leading_slash: true).and_return('tag-versions-s3-compiled-pathname')

      expect(TagsafeAws::S3).to receive(:write_to_s3).with(
        bucket: "tagsafe-#{Rails.env}-tag-versions",
        content: File.read(capturer.send(:js_file)),
        key: 'tag-versions-s3-compiled-pathname',
        cache_control: 'public, immutable, max-age=31536000, stale-while-revalidate=86400', # cache for 1 year
        acl: 'public-read',
        content_type: 'text/javascript',
      ).exactly(:once)

      expect(TagsafeAws::S3).to receive(:write_to_s3).with(
        bucket: "tagsafe-#{Rails.env}-tag-versions",
        content: File.read(capturer.send(:formatted_js_file)),
        key: 'tag-versions-s3-formatted-pathname',
        cache_control: 'public, immutable, max-age=31536000, stale-while-revalidate=86400', # cache for 1 year
        acl: 'public-read',
        content_type: 'text/javascript',
      ).exactly(:once)

      capturer.send(:upload_files_to_s3!, tag_version)
    end
  end
end