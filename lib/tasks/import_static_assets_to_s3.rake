def get_img_from_s3(file)
  TagsafeS3.client.get_object({ bucket: ENV['ASSET_S3_BUCKET'], key: File.basename(file), acl: 'public-read' })
rescue Aws::S3::Errors::NoSuchKey => e
end

def upload_local_img_to_s3(file)
  puts "Uploading #{File.basename(file)} to S3..."
  TagsafeS3.client.put_object({ bucket: ENV['ASSET_S3_BUCKET'], key: File.basename(file), body: file })
end

def handle_file_in_image_directory(filepath, counter_obj)
  if File.directory?(filepath)
    puts "#{File.basename(filepath)} is a directory, iterating over its files..."
    Dir.glob("#{filepath}/*").each{ |nested_filepath| handle_file_in_image_directory(nested_filepath) }
  else
    puts "Optimizing #{File.basename(filepath)} if necessary..."
    ImageOptimizer.new(filepath, quiet: true).optimize
    file = File.open(filepath)
    puts "Checking if #{File.basename(filepath)} exists in S3...."
    existing_s3_asset = get_img_from_s3(file)
    if existing_s3_asset
      existing_s3_asset_hash = Digest::MD5.hexdigest(existing_s3_asset.body.read)
      local_asset_hash = Digest::MD5.hexdigest(file.read)
      if existing_s3_asset_hash != local_asset_hash
        puts "#{File.basename(filepath)} exists in S3, but there is a new local version (local hash = #{local_asset_hash} and s3 hash = #{existing_s3_asset_hash})"
        upload_local_img_to_s3(file)
        counter_obj[:upload_count] += 1
      else
        puts "#{File.basename(filepath)} already exists in S3 and has the same content! Skipping..."
        counter_obj[:skip_count] += 1
      end
    else
      puts "#{File.basename(filepath)} does not exist in S3"
      upload_local_img_to_s3(file)
      counter_obj[:upload_count] += 1
    end
  end
end

task :import_static_assets_to_s3 => :environment do
  start = Time.now
  image_dir_content = Dir.glob(Rails.root.join('public', 'images', '*'))
  COUNTER = { upload_count: 0, skip_count: 0 }
  image_dir_content.each{ |filepath| handle_file_in_image_directory(filepath, COUNTER) }
  puts "Completed S3 upload in #{Time.now - start} seconds. Uploaded #{COUNTER[:upload_count]} images, skipped #{COUNTER[:skip_count]} already existing images."
end