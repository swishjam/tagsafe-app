module Admin
  class ScriptImagesController < BaseController
    def index
      @script_images = ScriptImage.all
      render_breadcrumbs(text: 'Admin Script Images', active: true)
    end

    def show
      @script_image = ScriptImage.find(params[:id])
      render_breadcrumbs(
        url: admin_script_images_path, text: 'Admin Script Images',
        text: 'Admin Script Image', active: true
      )
    end
  
    def create
      ScriptImage.create(script_image_params)
      display_toast_message('Successfully created Script Image')
      redirect_to request.referrer
    end

    def destroy
      script_image = ScriptImage.find(params[:id])
      script_image.destroy
      display_toast_message('Successfully deleted Script Image')
      redirect_to admin_script_images_path
    end

    def apply_to_scripts
      script_image = ScriptImage.find(params[:id])
      scripts = script_image.apply_to_scripts
      display_toast_message("Applied image to #{scripts.count} scripts.")
      redirect_to request.referrer
    end

    def apply_all_to_scripts
      applied_scripts = 0
      ScriptImage.apply_all_to_scripts
      display_toast_message("Applied images to #{applied_scripts} scripts.")
      redirect_to admin_script_images_path
    end
  
    private
    
    def script_image_params
      params.require(:script_image).permit(:image)
    end
  end
end