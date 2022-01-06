module TagManager
  class JsBeautifier
    def initialize(read_file:, output_file:)
      @read_file = read_file
      @output_file = output_file
    end

    def beautify!(as_file_object: true)
      system "node format-js #{@read_file} #{@output_file}"
      as_file_object ? File.new(@output_file) : @output_file
    end
  end
end