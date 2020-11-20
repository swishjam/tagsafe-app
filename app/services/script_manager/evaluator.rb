class ScriptManager::Evaluator
  attr_accessor :script_change

  def initialize(script)
    @script = script
    @script_change = nil
  end

  def evaluate!
    @response = fetcher.fetch!
    log_script_check!
    if fetcher.response_code === 200
      @hashed_content = ScriptManager::Hasher.hash!(@response.body)

      try_script_change!
    else
      Rails.logger.error "Fetch for #{@script.url} (id: #{@script.id}) resulted in a #{@response.code} response code. Skipping script change creation and test runs."
    end
  end

  def script_changed?
    !@script_change.nil?
  end

  private

  def fetcher
    @fetcher ||= ScriptManager::Fetcher.new(@script.url)
  end

  def log_script_check!
    if @script.should_log_script_checks
      ScriptCheck.create(
        response_time_ms: fetcher.response_time_ms, 
        response_code: fetcher.response_code, 
        script: @script
      )
    end
  end

  def try_script_change!
    if should_log_script_change?
      Resque.logger.info "Capturing a change to script: #{@script.url}."
      @script_change = ScriptManager::ChangeProcessor.new(@script, @response.body, hashed_content: @hashed_content).process_change!
    end
  end

  def should_log_script_change?
    @script.first_eval? || script_content_changed?
  end

  def script_content_changed?
    @script.most_recent_result.hashed_content != @hashed_content
  end
end