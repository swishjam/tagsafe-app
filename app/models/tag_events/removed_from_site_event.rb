class RemovedFromSiteEvent < TagEvent
  after_create :unremove_from_site_if_necessary

  def unremove_from_site_if_necessary
    tag.touch(:removed_from_site_at)
  end
end