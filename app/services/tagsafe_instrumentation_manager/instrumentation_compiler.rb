module TagsafeInstrumentationManager
  class InstrumentationCompiler
    def initialize(domain)
      @domain = domain
    end

    def compile_instrumentation
      @compile_instrumentation_result ||= begin
        generate_config_file
        run_webpack_system_command
      end
    end
    alias compile_instrumentation_if_necessary compile_instrumentation
    
    def compiled_instrumentation
      compile_instrumentation_if_necessary
      File.read(compiled_instrumentation_file_path)
    end

    def delete_compiled_instrumentation_file
      File.delete(compiled_instrumentation_file_path)
    end

  private

    def run_webpack_system_command
      Dir.chdir(Rails.root.join('tagsafe-instrumentation')) do 
        system "npm run build -- --env outputFilename=#{compiled_instrumentation_local_file_name}" 
      end
    end

    def generate_config_file
      @generated_config_file ||= InstrumentationConfigGenerator.new(@domain).write_instrumentation_config_file
    end

    def compiled_instrumentation_file_path
      Rails.root.join('tagsafe-instrumentation', 'build', "#{compiled_instrumentation_local_file_name}.js")
    end

    def compiled_instrumentation_local_file_name
      "#{@domain.uid}-instrumentation"
    end
  end
end