unless File.exists? File.expand_path('../credentials.yml', __FILE__)
  puts <<-EOS
--------------------------------------------------------------------------------
! Failed to load spec/credentials.yml. Please copy
! spec/credentials.yml.dist to spec/credentials.yml and define a valid
! project_guid to run the tests.
--------------------------------------------------------------------------------
  EOS
  exit
end

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
$LOAD_PATH.uniq!

def get_credentials
  YAML.load(File.read(File.expand_path('../credentials.yml', __FILE__)))
end

def get_api_client
  credentials = get_credentials()
  VCCSystem.configure do |config|
    config.project_guid = credentials['project_guid'] || 'a0b1c2d3-e4f5-a0b1-c2d3-e4f5a0b1c2d3'
    config.api_token = credentials['api_token'] if credentials['api_token']
  end
  VCCSystem::APIClient.new(debug: true)
end

RSpec.configure do |config|
  config.fail_fast = true
  config.filter_run_excluding :disabled => true
end
