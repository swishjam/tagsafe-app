module TagsafeInstrumentationManager
  class InstrumentationCompiler
    class InstrumentationBuildFailedError < StandardError; end;

    def initialize(container, type = 'tag-manager')
      @container = container
      @type = type
    end

    def compile_instrumentation
      unless @container.tagsafe_js_disabled?
        copy_instrumentation_directory_to_unique_directory
        generate_config_file
        run_webpack_system_command
      end
    end
    alias compile_instrumentation_if_necessary compile_instrumentation
    
    def compiled_instrumentation
      raise 'Must call `compile_instrumentation` before reference `compiled_instrumentation`.' if @container.tagsafe_js_enabled? && !File.exists?(compiled_instrumentation_file_path)
      if @container.tagsafe_js_enabled?
        File.read(compiled_instrumentation_file_path)
      else
        "console.warn('TagsafeJS disabled');"
      end
    end

    def delete_compiled_instrumentation_file
      return unless Dir.exist?(unique_directory_for_containers_instrumentation)
      FileUtils.rm_rf(unique_directory_for_containers_instrumentation)
    end

    private

    def copy_instrumentation_directory_to_unique_directory
      delete_compiled_instrumentation_file if Dir.exists?(unique_directory_for_containers_instrumentation)
      dir_to_copy = Rails.root.join(
        @type == 'speed-optimization' ? 
          'tagsafe-speed-optimizer-instrumentation' :
          @container.tagsafe_js_reporting_disabled? ? 'tagsafe-instrumentation-without-reporting' : 'tagsafe-instrumentation'
      )
      FileUtils.copy_entry(dir_to_copy, unique_directory_for_containers_instrumentation)
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