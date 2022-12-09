module TagsafeInstrumentationManager
  class InstrumentationCompiler
    def initialize(domain)
      @domain = domain
    end

    def compile_instrumentation
      @compile_instrumentation_result ||= begin
        copy_instrumentation_directory_to_unique_directory
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
      FileUtils.rm_rf(unique_directory_for_domains_instrumentation)
    end

    private

    def copy_instrumentation_directory_to_unique_directory
      FileUtils.copy_entry(Rails.root.join('tagsafe-instrumentation'), unique_directory_for_domains_instrumentation)
    end

    def run_webpack_system_command
      Dir.chdir(unique_directory_for_domains_instrumentation){ system "npm run build" }
    end

    def generate_config_file
      @generated_config_file ||= InstrumentationConfigGenerator.new(@domain).write_instrumentation_config_file
    end

    def unique_directory_for_domains_instrumentation
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@domain.uid}")
    end

    def compiled_instrumentation_file_path
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@domain.uid}", 'build', "output.js")
    end
  end
end