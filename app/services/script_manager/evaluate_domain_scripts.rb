module ScriptManager
  class EvaluateDomainScripts
    def initialize(domain, new_script_urls)
      @domain = domain
      @new_script_urls = new_script_urls
      @first_scan = @domain.scripts.count.zero?
    end

    def evaluate!
      evaluate_provided_scripts
    end

    private

    def evaluate_provided_scripts
      @new_script_urls.each do |url|
        remove_url_from_existing_urls(url)
        existing_script = Script.find_by(url: url)
        if existing_script
          subscribe_domain_to_existing_script(existing_script)
        else
          subscribe_domain_to_new_script(url)
        end
      end
      remove_scripts_no_longer_on_domain
    end

    def subscribe_domain_to_existing_script(script)
      unless @domain.subscribed_to_script? script
        @domain.subscribe!(script, first_script_change: script.most_recent_change, first_scan: @first_scan)
        # No audits should be run. The script subscriber is inactive. We will run audits upon activation.
        # script_subscriber.run_audit!(script_subscriber.script.most_recent_change, ExecutionReason.FIRST_AUDIT)
      end
    end

    def subscribe_domain_to_new_script(url)
      script = Script.create(url: url, should_log_script_checks: false)
      evaluator = script.evaluate_script_content
      @domain.subscribe!(script, first_script_change: evaluator.script_change, first_scan: @first_scan)
    end

    def remove_scripts_no_longer_on_domain
      existing_script_urls.each do |url|
        script_subscriber = @domain.script_subscriptions.joins(:script).find_by(scripts: { url: url })
        script_subscriber.removed_from_site!
      end
    end

    def remove_url_from_existing_urls(url)
      existing_script_urls.delete(url)
    end

    def existing_script_urls
      @existing_script_urls ||= @domain.scripts.collect(&:url)
    end
  end
end