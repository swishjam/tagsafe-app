module Admin
  class TagImagesController < BaseController
    def index
      @tag_images = TagImage.all
    end

    def show
      @tag_image = TagImage.find(params[:id])
    end
  
    def create
      TagImage.create(tag_image_params)
      display_toast_message('Successfully created Tag Image')
      redirect_to request.referrer
    end

    def destroy
      tag_image = TagImage.find(params[:id])
      tag_image.destroy
      display_toast_message('Successfully deleted Tag Image')
      redirect_to admin_tag_images_path
    end

    def apply_to_tags
      tag_image = TagImage.find(params[:id])
      scripts = tag_image.apply_to_tags
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
    
    def tag_image_params
      params.require(:tag_image).permit(:image)
    end
  end
end