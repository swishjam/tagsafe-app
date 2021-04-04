module Admin
  class TagImagesController < BaseController
    def index
      @script_images = TagImage.all
    end

    def show
      @script_image = TagImage.find(params[:id])
    end
  
    def create
      TagImage.create(script_image_params)
      display_toast_message('Successfully created Tag Image')
      redirect_to request.referrer
    end

    def destroy
      script_image = TagImage.find(params[:id])
      script_image.destroy
      display_toast_message('Successfully deleted Tag Image')
      redirect_to admin_script_images_path
    end

    def apply_to_scripts
      script_image = TagImage.find(params[:id])
      scripts = script_image.apply_to_scripts
      display_toast_message("Applied image to #{scripts.count} scripts.")
      redirect_to request.referrer
    end

    def apply_all_to_scripts
      applied_scripts = 0
      TagImage.apply_all_to_scripts
      display_toast_message("Applied images to #{applied_scripts} scripts.")
      redirect_to admin_script_images_path
    end
  
    private
    
    def script_image_params
      params.require(:script_image).permit(:image)
    end
  end
end