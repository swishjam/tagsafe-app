class ScriptManager::Evaluator
  attr_accessor :monitored_script

  def initialize(monitored_script)
    @monitored_script = monitored_script
  end

  def evaluate!
    response_data = ScriptManager::Fetcher.new(monitored_script.url).fetch!

    if should_log_script_change?(response_data)
      script_changed!(response_data)
    else
      # SILLY! and NOT WORKING! how do I log to rails AND resque!?
      Resque.logger.info "ScriptEvaluator Log Message (#{DateTime.current}): #{monitored_script.url} did not change from #{monitored_script.most_recent_result.hashed_content} hash."
      Rails.logger.info "ScriptEvaluator Log Message (#{DateTime.current}): #{monitored_script.url} did not change from #{monitored_script.most_recent_result.hashed_content} hash."
    end
  end

  private

  def should_log_script_change?(response_data)
    monitored_script.script_subscribers.empty? || monitored_script.most_recent_result.hashed_content != response_data[:hashed_content]
  end

  def script_changed!(data)
    data = clean_data(data) # just in case
    monitored_script.script_changes.create(data)
  end

  def clean_data(data)
    data.select { |key,_| [:content, :hashed_content, :bytes].include? key }
  end
end