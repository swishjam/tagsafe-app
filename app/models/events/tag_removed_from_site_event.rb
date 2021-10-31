class TagRemovedFromSiteEvent < Event
  after_create :remove_from_site_if_necessary

  def remove_from_site_if_necessary
    triggerer.touch(:removed_from_site_at)
  end
end