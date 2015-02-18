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

def load_credentials_yaml
  YAML.load(File.read(File.expand_path('../credentials.yml', __FILE__)))
end

def remove_all_agents
  # TODO
end

RSpec.configure do |config|
  config.fail_fast = true
end
