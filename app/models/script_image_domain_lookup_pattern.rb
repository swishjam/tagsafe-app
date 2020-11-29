class ScriptImageDomainLookupPattern < ApplicationRecord
  belongs_to :script_image

  def apply_image_to_script(override_existing_image = false)
    lookup_scripts.each do |script|
      script.update(script_image: script_image) if script.script_image.nil? || override_existing_image
    end
  end

  def lookup_scripts
    Script.where('url LIKE ?', "%#{url_pattern}%")
  end
end