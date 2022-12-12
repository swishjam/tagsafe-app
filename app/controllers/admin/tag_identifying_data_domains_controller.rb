module Admin
  class TagIdentifyingDataContainersController < BaseController
    def create
      tag_identifying_data = TagIdentifyingData.find_by(uid: params[:tag_identifying_datum_uid])
      params[:tag_identifying_data_container][:tag_identifying_data_id] = tag_identifying_data.id
      tag_identifying_data_container = tag_identifying_data.tag_identifying_data_containers.create(tag_identifying_data_container_params)
      tag_identifying_data_container.apply_to_tags_without_tag_identifying_data
      redirect_to tag_identifying_datum_path(tag_identifying_data)
    end

    private

    def tag_identifying_data_container_params
      params.require(:tag_identifying_data_container).permit(:tag_identifying_data_id, :url_pattern)
    end
  end
end