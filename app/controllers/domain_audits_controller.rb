class DomainAuditsController < LoggedInController
  skip_before_action :ensure_domain, only: :create
  before_action :ensure_current_domain_audit, except: :create

  def show
    render_breadcrumbs(text: "Third Party Tag Impact")
  end

  def bytes_breakdown
    tags = current_domain.tags
    url_crawl = current_domain_audit.url_crawl
    bar_chart_data = {}
    tags.order(last_captured_byte_size: :DESC).each do |tag| 
      if bar_chart_data[tag.try_friendly_name]
        bar_chart_data["#{tag.try_friendly_name} (#{tag.url_based_on_preferences})"] = tag.last_captured_byte_size
      else
        bar_chart_data[tag.try_friendly_name] = tag.last_captured_byte_size
      end
    end
    pie_chart_data = { 
      "First Party Javascript" => url_crawl.num_first_party_bytes,
      "Third Party Javascript" => url_crawl.num_third_party_bytes 
    }
    render turbo_stream: turbo_stream.replace(
      "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/bytes_breakdown',
      locals: { 
        domain_audit: current_domain_audit, 
        url_crawl: url_crawl,
        pie_chart_data: pie_chart_data,
        bar_chart_data: bar_chart_data
      }
    )
  end

  def performance_impact
    render turbo_stream: turbo_stream.replace(
      "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/performance_impact',
      locals: { 
        domain_audit: current_domain_audit, 
        url_crawl: current_domain_audit.url_crawl,
        average_delta_performance_audit: current_domain_audit.average_delta_performance_audit
      }
    )
  end

  def puppeteer_recording
    render turbo_stream: turbo_stream.replace(
      "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/puppeteer_recording',
      locals: {
        domain_audit: current_domain_audit,
        performance_audit_with_tag: current_domain_audit.median_individual_performance_audit_with_tags,
        performance_audit_without_tag: current_domain_audit.median_individual_performance_audit_without_tags
      }
    )
  end

  def tag_list
    url_crawl = current_domain_audit.url_crawl
    found_tags = url_crawl.found_tags.order(last_captured_byte_size: :DESC).page(params[:page]).per(10)
    domain = current_domain_audit.domain
    tag_with_audit = url_crawl.found_tags.includes(:audits).where.not(audits: { id: nil }).first
    render turbo_stream: turbo_stream.replace(
      "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/tag_list',
      locals: {
        domain_audit: current_domain_audit,
        domain: domain,
        url_crawl: url_crawl,
        found_tags: found_tags,
        tag_with_audit: tag_with_audit
      }
    )
  end

  def complete
    render turbo_stream: turbo_stream.replace(
      "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/complete',
      locals: { domain_audit: current_domain_audit }
    )
  end

  def create
    domain_url = params[:domain_url].starts_with?('http') ? params[:domain_url] : "https://#{params[:domain_url]}"
    domain = Domain.create(url: domain_url, is_generating_third_party_impact_trial: true)
    if domain.valid?
      domain_audit = DomainAudit.create(domain: domain, page_url: domain.page_urls.first)
      set_current_domain(domain)
      set_current_domain_audit(domain_audit)
      redirect_to third_party_impact_path
    else
      @domain_audit_error = domain.errors.full_messages.first
      render 'welcome/index', layout: 'logged_out_layout', status: :unprocessable_entity
    end
  end

  private

  def ensure_current_domain_audit
    redirect_to root_path if current_domain_audit.nil?
  end
end