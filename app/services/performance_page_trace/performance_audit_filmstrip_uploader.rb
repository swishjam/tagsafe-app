module PerformancePageTrace
  class PerformanceAuditFilmstripUploader
    def initialize(performance_audit)
      @performance_audit = performance_audit
    end

    def upload!
      screenshot_events = PerformancePageTrace::Parser.new(@performance_audit).get_filmstrip_screenshots
      screenshot_events.each do |screenshot| 
        # local_image_file = write_screenshot_to_disk(screenshot)
        # upload_screenshot(screenshot, local_image_file)
      end
    end

    private

    def upload_screenshot(screenshot)
      formatted_image_data(screenshot, local_image_file)
      # filmstrip_screenshot = FilmstripScreenshot.create(performance_audit: @performance_audit)
      # binding.pry
      # filmstrip_screenshot.image.attach(formatted_image_data(screenshot))
      # File.delete(Rails.root.join('tmp', "#{@performance_audit.uid}-filmstrip-screenshot-#{screenshot.ts}.png"))
    end

    def formatted_image_data(screenshot, local_image_file)
      { 
        io: File.open(local_image_file), 
        filename: "#{@performance_audit.uid}-filmstrip-screenshot-#{screenshot.ts}.png",
        content_type: 'image/png'
      }
    end

    def write_screenshot_to_disk(screenshot)
      @local_image_file = File.open(Rails.root.join('tmp', "#{@performance_audit.uid}-filmstrip-screenshot-#{rand(1_000_000)}-#{screenshot.ts}.png"), "wb")
      @local_image_file.write(Base64.decode64(screenshot.args['snapshot']))
      @local_image_file.close
      @local_image_file
    end
  end
end