module Admin
  class TagIdentifyingDataController < BaseController
    def index
      if params[:q]
        @tag_identifying_data = TagIdentifyingData.joins(:tag_identifying_data_domains)
                                                  .where("name like ?", "%#{params[:q]}%")
                                                  .order(name: :asc)
                                                  .page(params[:page] || 1).per(params[:per_page] || 9)
                                                  # .where("name like ? OR tag_identifying_domains.url_pattern like ?", "%#{params[:q]}%", "%#{params[:q]}%")
      else
        @tag_identifying_data = TagIdentifyingData.includes(:tag_identifying_data_domains)
                                                  .all
                                                  .order(name: :asc)
                                                  .page(params[:page] || 1).per(params[:per_page] || 9)
      end
    end

    def show
      @tag_identifying_data = TagIdentifyingData.find_by(uid: params[:uid])
    end
  
    def update
      tag_identifying_data = TagIdentifyingData.find_by(uid: params[:uid])
      tag_identifying_data.update(tag_identifying_data_params)
      redirect_to request.referrer
    end
  
    private
    
    def tag_identifying_data_params
      params.require(:tag_identifying_data).permit(:image)
    end
  end
end