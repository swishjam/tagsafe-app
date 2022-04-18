class DomainAuditsController < LoggedInController
  skip_before_action :ensure_domain, only: :create
  before_action :ensure_current_domain_audit, except: :create

  def show
    render_breadcrumbs(text: "Third Party Tag Impact")
  end

  def global_bytes_breakdown
    url_crawl = current_domain_audit.url_crawl
    pie_chart_data = { 
      "First Party Javascript" => url_crawl.num_first_party_bytes,
      "Third Party Javascript" => url_crawl.num_third_party_bytes 
    }
    render turbo_stream: turbo_stream.replace(
      params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/global_bytes_breakdown',
      locals: { 
        domain_audit: current_domain_audit, 
        url_crawl: url_crawl,
        num_third_party_tags: current_domain.tags.count,
        pie_chart_data: pie_chart_data
      }
    )
  end

  def individual_bytes_breakdown
    tags = current_domain.tags
    bar_chart_data = {}
    largest_tag = nil
    tags.order(last_captured_byte_size: :DESC).each do |tag| 
      largest_tag ||= tag
      if bar_chart_data[tag.try_friendly_name]
        bar_chart_data["#{tag.try_friendly_name} (#{tag.url_based_on_preferences})"] = tag.last_captured_byte_size
      else
        bar_chart_data[tag.try_friendly_name] = tag.last_captured_byte_size
      end
    end
    render turbo_stream: turbo_stream.replace(
      params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
      partial: 'domain_audits/individual_bytes_breakdown',
      locals: { 
        domain_audit: current_domain_audit, 
        url_crawl: current_domain_audit.url_crawl,
        bar_chart_data: bar_chart_data,
        largest_tag: largest_tag
      }
    )
  end

  def performance_impact
    if current_domain_audit.pending?
      render turbo_stream: turbo_stream.replace(
        params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
        partial: 'domain_audits/performance_impact',
        locals: { 
          domain_audit: current_domain_audit, 
          url_crawl: current_domain_audit.url_crawl,
          average_delta_performance_audit: nil,
          most_negative_performance_metric: nil,
          negative_performance_metrics: []
        }
      )
    else
      average_delta_performance_audit = current_domain_audit.average_delta_performance_audit
      negative_metrics = NegativePerformanceAuditMetricsIdentifier.new(average_delta_performance_audit)
      render turbo_stream: turbo_stream.replace(
        params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
        partial: 'domain_audits/performance_impact',
        locals: { 
          domain_audit: current_domain_audit, 
          url_crawl: current_domain_audit.url_crawl,
          average_delta_performance_audit: average_delta_performance_audit,
          most_negative_performance_metric: negative_metrics.most_negative_performance_metric,
          negative_performance_metrics: negative_metrics.negative_performance_metrics
        }
      )
    end
  end

  def puppeteer_recording
    render turbo_stream: turbo_stream.replace(
      params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
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
    found_tags = url_crawl.found_tags.order(last_captured_byte_size: :DESC).page(params[:page]).per(5)
    domain = current_domain_audit.domain
    tag_with_audit = url_crawl.found_tags.includes(:audits).where.not(audits: { id: nil }).first
    render turbo_stream: turbo_stream.replace(
      params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
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
      params[:frame_to_replace] || "domain_audit_#{current_domain_audit.uid}_results_component",
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