class ScriptImageDomainLookupPattern < ApplicationRecord
  belongs_to :script_image

  def self.find_and_apply_image_to_script(script)
    all.includes(:script_image).each do |pattern|
      if pattern.matches?(script.url)
        script.update(script_image: pattern.script_image)
        return script
      end
    end
  end

  def apply_image_to_scripts_with_matching_pattern(override_existing_image = false)
    scripts_matching_url_pattern = lookup_scripts!
    scripts_matching_url_pattern.each do |script|
      script.update(script_image: script_image) if script.script_image.nil? || override_existing_image
    end
  end

  def lookup_scripts!
    Script.where('url LIKE ?', "%#{url_pattern}%")
  end

  def matches?(script_url)
    script_url.include?(url_pattern)
  end
end