module ScriptManager
  class EvaluateDomainScripts
    def initialize(domain, new_script_urls, initial_scan)
      @domain = domain
      @new_script_urls = new_script_urls
      @initial_scan = initial_scan
    end

    def evaluate!
      evaluate_provided_scripts
    end

    private

    def evaluate_provided_scripts
      @new_script_urls.each do |url|
        remove_url_from_already_subscribed_urls(url)
        existing_script_full_url = Script.find_by(full_url: url)
        if existing_script_full_url
          subscribe_domain_to_existing_script(existing_script_full_url)
        else
          subscribe_domain_to_new_script(url)
        end
      end
      remove_scripts_no_longer_on_domain
    end

    def subscribe_domain_to_existing_script(script)
      unless @domain.subscribed_to_script?(script)
        if script.most_recent_change.nil?
          evaluator = script.capture_script_content
          @domain.subscribe!(script, first_script_change: evaluator.script_change, initial_scan: @initial_scan)    
        else
          @domain.subscribe!(script, first_script_change: script.most_recent_change, initial_scan: @initial_scan)
        end
      end
    end

    def subscribe_domain_to_new_script(url)
      parsed_url = URI.parse(url)
      # create the new script regardless of whether it was just a query param change...?
      script = Script.create(
        full_url: url, 
        url_domain: parsed_url.host, 
        url_path: parsed_url.path, 
        url_query_params: parsed_url.query, 
        should_log_script_checks: @domain.organization.should_log_script_checks
      )
      evaluator = script.capture_script_content

      # there can be many scripts with the same domain/path, which should we be finding....?
      existing_script_without_query_params = Script.most_recent_first.find_by(url_domain: parsed_url.host, url_path: parsed_url.path)
      if existing_script_without_query_params
        @domain.script_subscribers.find_by_domain_and_path(parsed_url.host, parsed_url.path)
      else
        @domain.subscribe!(script, first_script_change: evaluator.script_change, initial_scan: @initial_scan)
      end
    end

    def remove_scripts_no_longer_on_domain
      already_subscribed_script_urls.each do |url|
        script_subscriber = @domain.script_subscriptions.joins(:script).find_by(scripts: { full_url: url })
        script_subscriber.removed_from_site!
      end
    end

    def remove_url_from_already_subscribed_urls(url)
      already_subscribed_script_urls.delete(url)
    end

    def already_subscribed_script_urls
      @already_subscribed_script_urls ||= @domain.scripts.collect(&:url)
    end
  end
end