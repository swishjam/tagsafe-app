require 'rails_helper'

RSpec.describe LighthouseManager::ResultsHandler do
  before(:each) do
    stub_script_valid_url_validation
    domain = create(:domain)
    script = create(:script)
    @script_subscriber =  create(:script_subscriber, domain: domain, script: script)
    @script_change = create(:script_change, script: script)
    script_change_execution_reason = create(:script_change_execution)
    @audit = create(:audit, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: script_change_execution_reason, 
      lighthouse_audit_completed_at: nil
    )

    @results_with_tag = [create_results_obj(3, 1)]
    @results_without_tag = [create_results_obj(1, 2)]
  end

  def create_results_obj(value_multiplier, score_multiplier)
    {
      "lighthouse_report_url"=>"http://localhost:8080/lighthouse-reports/report-1603857356164.html",
      "max-potential-fid"=>{"value"=>100*value_multiplier, "score"=>0.1*score_multiplier},
      "largest-contentful-paint"=>{"value"=>2000*value_multiplier, "score"=>0.1*score_multiplier},
      "first-meaningful-paint"=>{"value"=>2000*value_multiplier, "score"=>0.1*score_multiplier},
      "first-contentful-paint"=>{"value"=>2000*value_multiplier, "score"=>0.1*score_multiplier},
      "estimated-input-latency"=>{"value"=>12*value_multiplier, "score"=>0.1*score_multiplier},
      "cumulative-layout-shift"=>{"value"=>0*value_multiplier, "score"=>0.1*score_multiplier},
      "first-cpu-idle"=>{"value"=>2000*value_multiplier, "score"=>0.1*score_multiplier},
      "total-byte-weight"=>{"value"=>10000*value_multiplier, "score"=>0.1*score_multiplier},
      "speed-index"=>{"value"=>3000*value_multiplier, "score"=>0.1*score_multiplier},
      "total-blocking-time"=>{"value"=>100*value_multiplier, "score"=>0.1*score_multiplier},
      "network-rtt"=>{"value"=>75*value_multiplier, "score"=>nil},
      "interactive"=>{"value"=>1000*value_multiplier, "score"=>0.1*score_multiplier},
      "mainDocumentTransferSize"=>{"value"=>100*value_multiplier},
      "maxRtt"=>{"value"=>75*value_multiplier},
      "maxServerLatency"=>{"value"=>25*value_multiplier},
      "numFonts"=>{"value"=>0*value_multiplier},
      "numRequests"=>{"value"=>6*value_multiplier},
      "numScripts"=>{"value"=>2*value_multiplier},
      "numStylesheets"=>{"value"=>1*value_multiplier},
      "numTasks"=>{"value"=>100*value_multiplier},
      "numTasksOver10ms"=>{"value"=>10*value_multiplier},
      "numTasksOver25ms"=>{"value"=>5*value_multiplier},
      "numTasksOver50ms"=>{"value"=>3*value_multiplier},
      "numTasksOver100ms"=>{"value"=>2*value_multiplier},
      "numTasksOver500ms"=>{"value"=>0*value_multiplier},
      "rtt"=>{"value"=>75*value_multiplier},
      "throughput"=>{"value"=>100*value_multiplier},
      "totalByteWeight"=>{"value"=>100*value_multiplier},
      "totalTaskTime"=>{"value"=>100*value_multiplier}
    }
  end

  def initialize_results_handler(error = nil)
    LighthouseManager::ResultsHandler.new(
      audit_id: @audit.id,
      results_with_tag: @results_with_tag,
      results_without_tag: @results_without_tag,
      error: error
    )
  end

  describe '#initialize' do
    it 'does not fail' do
      initialize_results_handler
    end
  end

  describe '#capture_results!' do
    it 'calls capture_results! on the handlers correctly' do
      raw_results_capture_results_count = 0
      average_results_capture_results_count = 0
      delta_results_capture_results_count = 0

      results_handler = initialize_results_handler

      expect(LighthouseManager::RawResultsHandler).to receive(:new).exactly(2).times.and_call_original
      allow_any_instance_of(LighthouseManager::RawResultsHandler).to receive(:capture_results!) do |raw_result_handler|
        raw_results_capture_results_count += 1
        raw_result_handler
      end
      allow_any_instance_of(LighthouseManager::RawResultsHandler).to receive(:average_results).at_least(:once)

      allow_any_instance_of(LighthouseManager::AverageResultsHandler).to receive(:capture_results!) do |raw_result_handler|
        average_results_capture_results_count += 1
        raw_result_handler
      end

      allow_any_instance_of(LighthouseManager::DeltaResultsHandler).to receive(:capture_results!) do |raw_result_handler|
        delta_results_capture_results_count += 1
        raw_result_handler
      end
      
      results_handler.capture_results!

      expect(raw_results_capture_results_count).to eq(2)
      expect(average_results_capture_results_count).to eq(2)
      expect(delta_results_capture_results_count).to eq(1)
    end
  end
end