class ScriptManager::ChangeProcessor
  def initialize(script, content, hashed_content: nil)
    @script = script
    @content = content
    @hashed_content = hashed_content
  end

  def process_change!
    @script.script_changes.create!(formatted_data)
  end

  private

  def formatted_data
    {
      hashed_content: @hashed_content || ScriptManager::Hasher.hash!(@content),
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
    "#{@script.id}-#{Time.current.to_i}.js"
  end

  def written_file_location
    "#{Util.create_dir_if_neccessary(Rails.root, 
                                      'public',
                                      'script_changes',
                                      @script.id.to_s, 
                                      Time.now.month.to_s, 
                                      Time.now.day.to_s)}/#{@hashed_content}.js"
  end
end