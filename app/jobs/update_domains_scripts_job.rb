class UpdateDomainsScriptsJob < ApplicationJob
  @queue = :default
  
  def perform(domain, script_urls)
    ScriptManager::EvaluateDomainScripts.new(domain, script_urls).evaluate!
  end
end