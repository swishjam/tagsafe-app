module TagManager
  class JsBeautifier
    def initialize(read_file:, output_file:)
      @read_file = read_file
      @output_file = output_file
    end

    # def self.beautify_in_memory!(content)
    #   read_file = Rails.root.join("tmp", "#{SecureRandom.hex}.js")
    #   beautifed_file_obj = new(
    #     read_file: read_file, 
    #     output_file: Rails.root.join("tmp", "#{SecureRandom.hex}.js")
    #   ).beautify!
    #   File.read(beautifed_file_obj)
    # end

    def beautify!(as_file_object: true)
      if system "node node-files/js-formatter #{@read_file} #{@output_file}"
        as_file_object ? File.new(@output_file) : @output_file
      else
        raise StandardError, "js-formatted failed!"
      end
    end
  end
end