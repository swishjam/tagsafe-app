module TagsafeInstrumentationManager
  class InstrumentationCompiler
    class InstrumentationBuildFailedError < StandardError; end;

    def initialize(container)
      @container = container
    end

    def compile_instrumentation
      copy_instrumentation_directory_to_unique_directory
      generate_config_file
      run_webpack_system_command
    end
    alias compile_instrumentation_if_necessary compile_instrumentation
    
    def compiled_instrumentation
      raise 'Must call `compile_instrumentation` before reference `compiled_instrumentation`.' unless File.exists?(compiled_instrumentation_file_path)
      File.read(compiled_instrumentation_file_path)
    end

    def delete_compiled_instrumentation_file
      FileUtils.rm_rf(unique_directory_for_containers_instrumentation)
    end

    private

    def copy_instrumentation_directory_to_unique_directory
      delete_compiled_instrumentation_file if Dir.exists?(unique_directory_for_containers_instrumentation)
      FileUtils.copy_entry(Rails.root.join('tagsafe-instrumentation'), unique_directory_for_containers_instrumentation)
    end

    def run_webpack_system_command
      Dir.chdir(unique_directory_for_containers_instrumentation) do 
        build_succeeded = system "npm run build" 
        raise InstrumentationBuildFailedError , "Unable to build instrumentation for Container #{@container.uid}" unless build_succeeded
      end
      true
    end

    def generate_config_file
      @generated_config_file ||= InstrumentationConfigGenerator.new(@container).write_instrumentation_config_file
    end

    def unique_directory_for_containers_instrumentation
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@container.uid}")
    end

    def compiled_instrumentation_file_path
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@container.uid}", 'build', "output.js")
    end
  end
end