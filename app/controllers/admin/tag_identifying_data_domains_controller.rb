module Admin
  class TagIdentifyingDataDomainsController < BaseController
    def create
      tag_identifying_data = TagIdentifyingData.find_by(uid: params[:tag_identifying_datum_uid])
      params[:tag_identifying_data_domain][:tag_identifying_data_id] = tag_identifying_data.id
      tag_identifying_data_domain = tag_identifying_data.tag_identifying_data_domains.create(tag_identifying_data_domain_params)
      tag_identifying_data_domain.apply_to_tags_without_tag_identifying_data
      redirect_to tag_identifying_datum_path(tag_identifying_data)
    end

    private

    def tag_identifying_data_domain_params
      params.require(:tag_identifying_data_domain).permit(:tag_identifying_data_id, :url_pattern)
    end
  end
end