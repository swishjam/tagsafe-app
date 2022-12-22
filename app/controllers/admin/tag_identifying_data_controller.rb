module Admin
  class TagIdentifyingDataController < BaseController
    def index
      if params[:q]
        @tag_identifying_data = TagIdentifyingData.joins(:tag_identifying_data_containers)
                                                  .where("name like ?", "%#{params[:q]}%")
                                                  .order(name: :asc)
                                                  .page(params[:page] || 1).per(params[:per_page] || 9)
                                                  # .where("name like ? OR tag_identifying_containers.url_pattern like ?", "%#{params[:q]}%", "%#{params[:q]}%")
      else
        @tag_identifying_data = TagIdentifyingData.includes(:tag_identifying_data_containers)
                                                  .all
                                                  .order(name: :asc)
                                                  .page(params[:page] || 1).per(params[:per_page] || 9)
      end
    end

    def new
      @tag_identifying_data = TagIdentifyingData.new
    end

    def create
      @tag_identifying_data = TagIdentifyingData.new(tag_identifying_data_params)
      if @tag_identifying_data.save
        redirect_to admin_tag_identifying_datum_path(@tag_identifying_data)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @tag_identifying_data = TagIdentifyingData.find_by(uid: params[:uid])
    end
  
    def update
      tag_identifying_data = TagIdentifyingData.find_by(uid: params[:uid])
      tag_identifying_data.update(tag_identifying_data_image_params)
      redirect_to request.referrer
    end
  
    private

    def tag_identifying_data_params
      params.require(:tag_identifying_data).permit(:name, :company, :homepage, :category)
    end
    
    def tag_identifying_data_image_params
      params.require(:tag_identifying_data).permit(:image)
    end
  end
end