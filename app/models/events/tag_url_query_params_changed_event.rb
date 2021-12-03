class TagUrlQueryParamsChangedEvent < Event
  store :metadata, accessors: %i[removed_url_query_params added_url_query_params]
  
  after_create :update_tag_with_new_query_params

  def update_tag_with_new_query_params
    triggerer.update!(full_url: "#{triggerer.url_scheme}://#{triggerer.url_domain}#{triggerer.url_path}#{added_url_query_params}", url_query_param: added_url_query_params)
  end
end