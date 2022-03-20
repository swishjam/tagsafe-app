class DomainAuditsController < LoggedInController
  skip_before_action :ensure_domain, only: :create

  def show
    @domain_audit = DomainAudit.includes(:domain, :average_delta_performance_audit, url_crawl: :found_tags).find_by(uid: params[:id])
    @average_delta_performance_audit = @domain_audit.average_delta_performance_audit
    @domain = @domain_audit.domain
    @url_crawl = @domain_audit.url_crawl
    # @url_crawl = UrlCrawl.first
    @found_tags = @url_crawl.found_tags.page(params[:page] || 1).per(params[:per_page] || 50)
  end

  def create
    generator = DomainAuditGenerator.new(params[:domain_url])
    generator.create_domain_audit
    if generator.domain_audit && generator.domain_audit.valid?
      set_current_domain(generator.domain_audit.domain)
      set_current_domain_audit(generator.domain_audit)
      redirect_to domain_audit_path(generator.domain_audit.uid)
    else
      @domain_audit_error = generator.domain.errors.full_messages.first || generator.page_url.errors.full_messages.first || generator.domain_audit.errors.full_messages.first
      render 'welcome/index', layout: 'logged_out_layout', status: :unprocessable_entity
    end
  end
end