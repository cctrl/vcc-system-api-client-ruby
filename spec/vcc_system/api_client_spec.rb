require 'spec_helper'

require 'yaml'
require 'vcc_system/api_client'


RSpec.describe VCCSystem::APIClient do

  let(:client) do
    credentials = load_credentials_yaml()
    project_guid = credentials['project_guid'] || 'a0b1c2d3-e4f5-a0b1-c2d3-e4f5a0b1c2d3'
    VCCSystem::APIClient.new(project_guid, debug: true)
  end

  it 'should create an agent' do
    vcc_id = client.vcc_agent_add(1001)
    expect(vcc_id).to be > 0
  end

end
