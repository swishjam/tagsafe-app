class UrlQueryParamsChangedEvent < TagEvent
  include ContextualUid
  store :metadata, accessors: %i[removed_url_query_params added_url_query_params]
  
  after_create :update_tag_with_new_query_params

  def update_tag_with_new_query_params
    tag.update!(full_url: tag.url_domain + tag.url_path + added_url_query_params, url_query_param: added_url_query_params)
  end
end