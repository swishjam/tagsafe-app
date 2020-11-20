puts "Beginning seed."

puts "Creating Script Test Types."
script_test_types = ['Current Tag', 'Previous Tag', 'Without Tag']
script_test_types.each do |name|
  unless ScriptTestType.find_by(name: name)
    ScriptTestType.create(name: name)
  end
end 

puts "Creating Execution Reasons."
execution_reasons =  ['Manual Execution', 'Scheduled Execution', 'Script Change', 'Reactivated Script', 'Test']
execution_reasons.each do |name|
  unless ExecutionReason.find_by(name: name)
    ExecutionReason.create(name: name)
  end
end

lighthouse_audit_result_metric_types = {
  'max-potential-fid': {
    result_unit: 'milliseconds',
    title: 'Max Potential First Input Delay'
  },
  'largest-contentful-paint': {
    result_unit: 'milliseconds',
    title: 'Largest Contentful Paint'
  },
  'first-meaningful-paint': {
    result_unit: 'milliseconds',
    title: 'First Meaningful Paint'
  },
  'first-contentful-paint': {
    result_unit: 'milliseconds',
    title: 'First Contentful Paint'
  },
  'estimated-input-latency': {
    result_unit: 'milliseconds',
    title: 'Estimated Input Latency'
  },
  'cumulative-layout-shift': {
    result_unit: 'points',
    title: 'Cumulative Layout Shift'
  },
  'first-cpu-idle': {
    result_unit: 'milliseconds',
    title: 'First CPU Idle'
  },
  'total-byte-weight': {
    result_unit: 'bytes',
    title: 'Total Byte Weight'
  },
  'speed-index': {
    result_unit: 'points',
    title: 'Speed Index'
  },
  'render-blocking-resources': {
    result_unit: 'resources',
    title: 'Render Blocking Resources'
  },
  'network-rtt': {
    result_unit: 'milliseconds',
    title: 'Network Round Trip Time'
  },
  'interactive': {
    result_unit: 'milliseconds',
    title: 'DOM Interactive'
  },
  'mainDocumentTransferSize': {
    result_unit: 'bytes',
    title: 'Main Document Transfer Size'
  },
  'maxRtt': {
    result_unit: 'milliseconds',
    title: 'Max Round Trip Time'
  },
  'maxServerLatency': {
    result_unit: 'milliseconds',
    title: 'Max Server Latency'
  },
  'numFonts': {
    result_unit: 'fonts',
    title: 'Number of Fonts'
  },
  'numRequests': {
    result_unit: 'requests',
    title: 'Number of Requests'
  },
  'numScripts': {
    result_unit: 'scripts',
    title: 'Number of Scripts'
  },
  'numStylesheets': {
    result_unit: 'stylesheets',
    title: 'Number of Stylesheets'
  },
  'numTasks': {
    result_unit: 'tasks',
    title: 'Number of Tasks'
  },
  'numTasksOver10ms': {
    result_unit: 'tasks',
    title: 'Number of Tasks Over 10ms'
  },
  'numTasksOver25ms': {
    result_unit: 'tasks',
    title: 'Number of Tasks Over 25ms'
  },
  'numTasksOver50ms': {
    result_unit: 'tasks',
    title: 'Number of Tasks Over 50ms'
  },
  'numTasksOver100ms': {
    result_unit: 'tasks',
    title: 'Number of Tasks Over 100ms'
  },
  'numTasksOver500ms': {
    result_unit: 'tasks',
    title: 'Number of Tasks Over 500ms'
  },
  'rtt': {
    result_unit: 'milliseconds',
    title: 'Round Trip Time'
  },
  'throughput': {
    result_unit: 'milliseconds',
    title: 'Throughput'
  },
  'totalByteWeight': {
    result_unit: 'bytes',
    title: 'Total Byte Weight'
  },
  'totalTaskTime': {
    result_unit: 'milliseconds',
    title: 'Total Task Time'
  }
}

puts "Creating Lighthouse Audit Metric Types/"
lighthouse_audit_result_metric_types.each do |key, val|
  lar_metric_type = LighthouseAuditResultMetricType.find_by(key: key)
  if lar_metric_type
    lar_metric_type.update(title: val[:title], result_unit: val[:result_unit])
  else
    LighthouseAuditMetricType.create(key: key, title: val[:title], result_unit: val[:result_unit])
  end
end

puts "Creating Domains."
org = Organization.find_or_create_by(name: 'Seeded Organization')
domains = %w[https://www.tagsafe.io htps://www.google.com https://www.quantummetric.com]
domains.each do |url|
  unless Domain.find_by(url: url)
    Domain.create(organization: org, url: url)
  end
end

puts "Creating Scripts and Script Changes."
scripts = %w[
  https://cdn.quantummetric.com/qscripts/quantum-collin.js 
  https://cdn.collin.com/js/script.js
  https://cdn.optimizely.com/script.js
  https://cdn.medallia.com/script.js
  https://cdn.qualtrics.com/survey.js
  https://cdn.gigya.com/script.js
  https://cdn.speedcurve.com/monitor.js
  https://cdn.rigor.com/scripts.js
  https://www.catchpoint.com/scripts/tag.js
]
scripts.each do |url|
  s = Script.create(url: url)
  
end

puts "Completed seed."