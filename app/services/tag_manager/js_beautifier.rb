module TagManager
  class JsBeautifier
    def initialize(read_file:, output_file:)
      @read_file = read_file
      @output_file = output_file
    end

    def beautify!(as_file_object: true)
      if system "node node-files/js-formatter #{@read_file} #{@output_file}"
        as_file_object ? File.new(@output_file) : @output_file
      else
        raise StandardError, "js-formatted failed!"
      end
    end
  end
end