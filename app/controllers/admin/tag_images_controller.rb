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
      redirect_to admin_tag_images_path
    end

    def apply_to_tags
      script_image = TagImage.find(params[:id])
      scripts = script_image.apply_to_tags
      display_toast_message("Applied image to #{scripts.count} scripts.")
      redirect_to request.referrer
    end

    def apply_all_to_tags
      applied_scripts = 0
      TagImage.apply_all_to_tags
      display_toast_message("Applied images to #{applied_scripts} scripts.")
      redirect_to admin_tag_images_path
    end
  
    private
    
    def script_image_params
      params.require(:script_image).permit(:image)
    end
  end
end