puts "Beginning seed."

puts "Creating Script Test Types."
script_test_types = ['Current Tag', 'Previous Tag', 'Without Tag']
script_test_types.each do |name|
  unless ScriptTestType.find_by(name: name)
    ScriptTestType.create(name: name)
  end
end 

puts "Creating Execution Reasons."
execution_reasons =  ['Manual Execution', 'Scheduled Execution', 'Tagript Change', 'Reactivated Tag', 'Test', 'Initial Audit']
execution_reasons.each do |name|
  unless ExecutionReason.find_by(name: name)
    ExecutionReason.create(name: name)
  end
end

performance_audit_result_metric_types = [
  { 
    key: 'DOMComplete',
    unit: 'milliseconds',
    title: 'DOM Complete'
  },
  { 
    key: 'DOMInteractive',
    unit: 'milliseconds',
    title: 'DOM Interactive'
  },
  { 
    key: 'FirstContentfulPaint',
    unit: 'milliseconds',
    title: 'First Contentful Paint'
  },
  { 
    key: 'TaskDuration',
    unit: 'milliseconds',
    title: 'Task Duration'
  },
  { 
    key: 'ScriptDuration',
    unit: 'milliseconds',
    title: 'Script Duration'
  },
  {
    key: 'LayoutDuration',
    unit: 'milliseconds',
    title: 'Layout Duration'
  }
]



puts "Creating Lighthouse Audit Metric Types"
performance_audit_result_metric_types.each do |metric|
  metric_type = PerformanceAuditMetricType.find_by(key: metric[:key])
  if metric_type
    metric_type.update(title: metric[:title], unit: metric[:unit], description: metric[:description])
  else
    PerformanceAuditMetricType.create(key: metric[:key], title: metric[:title], unit: metric[:unit], description: metric[:description])
  end
end

puts "Purging existing seed data."
domain_urls = %w[https://www.tagsafe.io htps://www.google.com https://www.quantummetric.com]
script_urls = %w[
  https://cdn.collin.com/js/script.js
  https://cdn.optimizely.com/script.js
  https://cdn.medallia.com/script.js
  https://cdn.qualtrics.com/survey.js
  https://cdn.gigya.com/script.js
  https://cdn.speedcurve.com/monitor.js
  https://cdn.rigor.com/scripts.js
  https://www.catchpoint.com/scripts/tag.js
]

domain_urls.each { |u| Domain.find_by(url: u)&.destroy! }
script_urls.each { |u| Script.find_by(url: u)&.destroy! }

puts "Creating Domains."
org = Organization.find_or_create_by(name: 'Seeded Organization')
unless User.find_by(email: 'seed@gmail.com')
  User.create(email: 'seed@gmail.com', password: 'seed123', organization: org)
end
domain_urls.each do |url|
  unless Domain.find_by(url: url)
    Domain.without_callbacks do
      puts "Creating domain #{url}"
      Domain.create(organization: org, url: url)
    end
  else
    puts "Domain #{url} already exists, skipping."
  end
end

puts "Creating Scripts and Script Changes."
def seed_script_changes_for_script(script)
  unless script.script_changes.any?
    ScriptChange.without_callbacks do
      5.times do |i|
        puts "Creating script change."
        ScriptChange.create(
          script: script,
          hashed_content: SecureRandom.hex(8),
          bytes: 1,
          created_at: DateTime.now - (i.days*rand(10))
        )
      end
    end
    most_recent = script.script_changes.most_recent_first.first
    most_recent.make_most_recent!
    most_recent.set_script_content_changed_at_timestamp
  end
  script.script_changes
end

def create_audit(script_change, script_subscriber, execution_reason: ExecutionReason.TAG_CHANGE)
  puts "Creating audit."
  Audit.create(
    script_change: script_change,
    script_subscriber: script_subscriber,
    execution_reason: execution_reason,
    lighthouse_audit_enqueued_at: execution_reason == ExecutionReason.TAG_CHANGE ? script_change.created_at : script_change.created_at + 1.hour,
    test_suite_enqueued_at: script_change.created_at,
    test_suite_completed_at: script_change.created_at,
    lighthouse_audit_url: script_subscriber.reload.lighthouse_preferences.url_to_audit
  )
end

def create_audits_for_script_changes(script_subscriber, script_changes)
  unless script_subscriber.audits.any?
    script_changes.each do |script_change|
      create_audit(script_change, script_subscriber)
      create_audit(script_change, script_subscriber, execution_reason: ExecutionReason.MANUAL)
    end
  end
  script_subscriber.audits
end

def generate_lighthouse_audit_result(value_multiplier = 10, score_multiplier = 10)
  {
    "max-potential-fid" => { "value" => (5*value_multiplier), "score" => (0.1*score_multiplier) },
    "largest-contentful-paint" => { "value" => (50*value_multiplier), "score" => (0.1*score_multiplier) },
    "first-meaningful-paint" => { "value" => (50*value_multiplier), "score" => (0.1*score_multiplier) },
    "first-contentful-paint" => { "value" => (50*value_multiplier), "score" => (0.1*score_multiplier) },
    "estimated-input-latency" => { "value" => (1*value_multiplier), "score" => (0.1*score_multiplier) },
    "cumulative-layout-shift" => { "value" => (0.1)*value_multiplier, "score" => (0.1*score_multiplier) },
    "first-cpu-idle" => { "value" => (70*value_multiplier), "score" => (0.1*score_multiplier) },
    "total-byte-weight" => { "value" => (200*value_multiplier),"score" => (0.1*score_multiplier) },
    "speed-index" => { "value" => (80*value_multiplier),"score" => (0.1*score_multiplier) },
    "render-blocking-resources" => { "value" => (50*value_multiplier),"score" => (0.1*score_multiplier) },
    "network-rtt" => { "value" => (0.00687*value_multiplier),"score" => nil },
    "interactive" => { "value" => (70*value_multiplier),"score" => (0.1*score_multiplier) },
    "total-blocking-time" => { "value" => (10*value_multiplier),"score" => (0.1*score_multiplier) },
    "mainDocumentTransferSize" => { "value" =>  (40*value_multiplier) },
    "maxRtt" => { "value" => (0.00687*value_multiplier) },
    "maxServerLatency" => { "value" => (0.1*value_multiplier) },
    "numFonts" => { "value" => (0*value_multiplier) },
    "numRequests" => { "value" => (1*value_multiplier) },
    "numScripts" => { "value" => (2*value_multiplier) },
    "numStylesheets" => { "value" => (1*value_multiplier) },
    "numTasks" => { "value" => (30*value_multiplier) },
    "numTasksOver10ms" => { "value" => (4*value_multiplier) },
    "numTasksOver25ms" => { "value" => (3*value_multiplier) },
    "numTasksOver50ms" => { "value" => (2*value_multiplier) },
    "numTasksOver100ms" => { "value" => (1*value_multiplier) },
    "numTasksOver500ms" => { "value" => (0*value_multiplier) },
    "rtt" => { "value" => (0.0015*value_multiplier) },
    "throughput" => { "value" => (40_000*value_multiplier) },
    "totalByteWeight" => { "value" => (2000*value_multiplier) },
    "totalTaskTime" => { "value" => (50*value_multiplier) }
    # "lighthouse_report_url":"http://localhost:3000/public/lighthouse-reports/report-1601770307147.html"
  }
end

def create_random_results_with_tag
  [
    generate_lighthouse_audit_result(Util.random_float(8, 10).round(2), Util.random_float(9, 10).round(2)),
    generate_lighthouse_audit_result(Util.random_float(10, 15).round(2), Util.random_float(6, 8).round(2)),
    generate_lighthouse_audit_result(Util.random_float(9, 12).round(2), Util.random_float(8, 9).round(2))
  ]
end

def create_random_results_without_tag
  3.times.map{ generate_lighthouse_audit_result(Util.random_float(8, 10).round(2), Util.random_float(9, 10).round(2)) }
end

def create_lighthouse_audits_for_audits(audits)
  audits.each do |audit|
    puts "Creating lighthouse audit."
    LighthouseManager::ResultsHandler.new(
      error: nil,
      results_with_tag: create_random_results_with_tag,
      results_without_tag: create_random_results_without_tag, 
      audit_id: audit.id
    ).capture_results!
  end
end

domains = domain_urls.map{ |url| Domain.find_by(url: url) }

script_urls.each do |url|
  script = Script.find_or_create_by(url: url)
  script_changes = seed_script_changes_for_script(script)
  domains.each do |domain|
    script_subscriber = domain.subscribed_to_script?(script) ? domain.script_subscriptions.find_by(script_id: script.id) : domain.subscribe!(script, active: true, monitor_changes: false)
    audits = create_audits_for_script_changes(script_subscriber, script_changes)
    create_lighthouse_audits_for_audits(audits)
  end
end

puts "Completed seed."