require 'json'
require 'fileutils'
require 'action_view'
include ActionView::Helpers::NumberHelper

def generate_outreach_from_results_file(file_path)
  file_name = file_path.split('/').last
  site_name = file_name.gsub('-results.json', '')
                          .gsub('www_', 'www.')
                          .gsub('_com', '.com')
                          .gsub('_net', '.net')
                          .gsub('_io', '.io')
                          .gsub('_org', '.org')
                          .gsub('_ca', '.ca')
  puts "Parsing results for #{site_name}"
  results_json = JSON.parse(File.read(file_path))
  words = <<~MESSAGE
    #{site_name} loads #{results_json['numThirdPartyJsRequests']} third party JS scripts, totaling in #{number_to_human_size(results_json['totalThirdPartyJsBytes'])} of javascript, while you are loading #{number_to_human_size(results_json['totalFirstPartyJsBytes'])} of 'first party javascript', meaning #{(results_json['percentOfJsIs3p'] || 0).round(2)}% of all the javascript loaded on the page originates from third party resources. 
    It takes #{site_name} #{(results_json['totalThirdPartyTime'] / 1_000 || 0).round(2)} seconds to download all of the third party javascript on the site. #{(results_json['percentOfThirdPartyJsRequestTimeIsDnsOrSsl'] || 0).round(2)}% of the third party JS download time is due to DNS lookups and SSL connections, which would be eliminated using Tagsafe. 
    If #{site_name} had zero third party javascript tags, it would cut the DOM Complete time by #{((results_json['DOMComplete']['cutMetricPercentage'] || 0) * 100).round(2)}%, the First Contentful Paint time by #{((results_json['FirstContentfulPaint']['cutMetricPercentage'] || 0) * 100).round(2)}%, and DOM Interactive time by #{((results_json['DOMInteractive']['cutMetricPercentage'] || 0) * 100).round(2)}%.
  MESSAGE
  File.write("./outreach/#{file_name.gsub('-results.json', '-outreach.txt')}", words)
  puts "Wrote outreach for #{site_name} to ./outreach/#{file_name.gsub('-results.json', '-outreach.txt')}"
end

<<<<<<< HEAD
Dir.glob('./results/www_prettylittlething_com-results.json'){ |file_path| generate_outreach_from_results_file(file_path) }
=======
Dir.glob('./results/mackweldon_com-results.json'){ |file_path| generate_outreach_from_results_file(file_path) }
>>>>>>> main

puts "DONE!"