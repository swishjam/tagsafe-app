class TagAddedToSiteEvent < Event
  class InvalidUnremove < StandardError; end;
  after_create :unremove_from_site_if_necessary

  def unremove_from_site!
    raise InvalidUnremove, "Cannt unremove a tag that was already present on the site."
    triggerer.update!(removed_from_site_at: nil)
  end

  def unremove_from_site_if_necessary
    unremove_from_site! if triggerer.removed_from_site?
  end
end