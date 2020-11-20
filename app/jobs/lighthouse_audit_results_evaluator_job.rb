class LighthouseAuditResultsEvaluatorJob < ApplicationJob
  def perform(error:, results_with_tag:, results_without_tag:, audit_id:)
    LighthouseManager::ResultsHandler.new(
      error: error,
      results_with_tag: results_with_tag,
      results_without_tag: results_without_tag,
      audit_id: audit_id
    ).capture_results!
  end
end


# {"max_potential_fid":{"value":38,"score":1},"largest_contentful_paint":{"value":773.63805,"score":0.98},"first_meaningful_paint":{"value":713.5579500000001,"score":0.97},"first_contentful_paint":{"value":713.5579500000001,"score":0.97},"estimated_input_latency":{"value":12.8,"score":1},"cumulative_layout_shift":{"value":0,"score":1},"first_cpu_idle":{"value":713.5579500000001,"score":1},"total_byte_weight":{"value":237053,"score":1},"speed_index":{"value":886.2958703782813,"score":0.99},"render_blocking_resources":{"value":505,"score":0.64},"network_rtt":{"value":0.0687,"score":nil},"interactive":{"value":713.5579500000001,"score":1},"mainDocumentTransferSize":{"value": 4032},"maxRtt":0.0687,"maxServerLatency":95.25229999999999,"numFonts":0,"numRequests":10,"numScripts":2,"numStylesheets":1,"numTasks":300,"numTasksOver10ms":4,"numTasksOver25ms":2,"numTasksOver50ms":1,"numTasksOver100ms":0,"numTasksOver500ms":0,"rtt":0.015299999999999998,"throughput":3964751.706309987,"totalByteWeight":237053,"totalTaskTime":243.14399999999975,"lighthouse_report_url":"http://localhost:3000/public/lighthouse-reports/report-1601770307147.html"}