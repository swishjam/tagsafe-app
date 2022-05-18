require 'yaml'
require 'json'

def prompt(*args)
  print(*args)
  gets.strip
end

root_dir = prompt "Enter directory name: "
app_name = prompt "Enter app name: "
service_name = prompt "Enter service name: "
function_name = prompt "Enter function name: "

puts "\n\nCreating new Lambda function:\nApp Name: #{app_name}\nService Name: #{service_name}\nFunction Name: #{function_name}\n\n"

system("mkdir #{root_dir}")
system("mkdir #{root_dir}/config")
system("mkdir #{root_dir}/src")

system("touch #{root_dir}/config/local.yml")
system("touch #{root_dir}/config/development.yml")
system("touch #{root_dir}/config/staging.yml")
system("touch #{root_dir}/config/production.yml")

system("touch #{root_dir}/serverless.yml")
File.open("#{root_dir}/serverless.yml", 'w') do |file|
  yaml = {
    'app' => app_name,
    'service' => service_name,
    'org' => 'collin',
    'frameworkVersion' => '2',
    'provider' => {
      'name' => 'aws',
      'runtime' => 'nodejs14.x',
      'lambdaHashingVersion' => 20201221,
      'stage' => '${opt:stage}',
      'environment' => {
        'NODE_ENV' => '${opt:stage}',
        'S3_AWS_ACCESS_KEY_ID' => 'AKIAV5V4H3GFRTGOCY52'
        'S3_AWS_SECRET_ACCESS_KEY' => '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'
      }
    },
    'functions' => {
      function_name => {
        'handler' => 'handler.handle',
        'timeout' => 60
      }
    }
  }.to_yaml
  file.write(yaml)
end

system("touch #{root_dir}/handler.js")
File.open("#{root_dir}/handler.js", 'w') do |file| 
  file.write(
    <<-JS
    'use strict';

    require('dotenv').config();

    module.exports.handle = async (event, context) => {
      return {
        statusCode: 202,
        body: JSON.generate('success')
      }
    }
    JS
  )
end

Dir.chdir(root_dir) {
  system('npm init')
  system('npm install chrome-aws-lambda dotenv puppeteer-core puppeteer-extra puppeteer-extra-plugin-stealth')
  system('npm install serverless-offline --save-dev')
}

json = JSON.parse(File.read("#{root_dir}/package.json"))
json['scripts'] = {
  "deploy-dev" => "serverless deploy --stage collin-dev",
  "deploy-stage" => "serverless deploy --stage staging",
  "deploy-prod" => "serverless deploy --stage production"
}

File.open("#{root_dir}/package.json", 'w'){ |file| file.write(JSON.pretty_generate(json)) }

puts "\n#{function_name} Lambda function successfully created in #{root_dir}\n\n"