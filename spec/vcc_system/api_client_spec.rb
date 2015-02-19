require 'spec_helper'

require 'yaml'
require 'vcc_system/api_client'


RSpec.describe VCCSystem::APIClient do

  let(:client) do
    credentials = load_credentials_yaml()
    project_guid = credentials['project_guid'] || 'a0b1c2d3-e4f5-a0b1-c2d3-e4f5a0b1c2d3'
    VCCSystem::APIClient.new(project_guid, debug: true)
  end

  describe "#vcc_agent_list" do
    let(:agents) do
      client.vcc_agent_list()
    end

    context "all agents allocated" do
      it 'should return an array' do
        expect(agents).to be_an_instance_of(Array)
      end

      #it 'should have ten agents' do
      #  expect(agents.count).to eq(10)
      #end

      #it 'should have first agent with crmname 1005' do
      #  expect(agents.first["crmname"]).to eq("1005")
      #end

      #it 'should have last agent with crmname 1001' do
      #  expect(agents.last["crmname"]).to eq("1001")
      #end

      it 'should delete all agents' do
        agents.each do |agent|
          client.vcc_agent_del(agent["exten"])
        end
      end
    end
  end

#  it 'should create an agent' do
#    vcc_id = client.vcc_agent_add(1001)
#    expect(vcc_id).to be > 0
#  end

end
