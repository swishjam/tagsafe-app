class ScriptsController < ApplicationController
  before_action :authorize!
  
  def index
    flash[:toast_messages] = ["Hello world"]
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('script_subscribers.active DESC')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 6)
    end
  end
end