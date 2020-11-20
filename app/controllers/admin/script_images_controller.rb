class ScriptImagesController < AdminController
  def index
    @script_images = ScriptImage.all
  end
end