class AddreRouteEligibleTagsSampleRateToContainers < ActiveRecord::Migration[6.1]
  def change
    add_column :containers, :tagsafe_js_re_route_eligible_tags_sample_rate, :float
  end
end
