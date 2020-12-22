class UpdateDomainsScriptsJob < ApplicationJob
  @queue = :default
  
  def perform(domain, script_urls, initial_scan)
    ScriptManager::EvaluateDomainScripts.new(domain, script_urls, initial_scan).evaluate!
  end
end