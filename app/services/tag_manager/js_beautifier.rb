module TagManager
  class JsBeautifier
    def initialize(read_file:, output_file:)
      @read_file = read_file
      @output_file = output_file
    end

    def beautify!
      system "node format-js #{@read_file} #{@output_file}"
      @output_file
    end
  end
end