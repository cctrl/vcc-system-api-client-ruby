require 'spec_helper'

require 'yaml'
require 'vcc_system/api_client'


RSpec.describe VCCSystem::APIClient do

  before(:context) do
    @client = get_api_client()
  end

  let(:agents) { @client.vcc_agent_list() }
  let(:campaigns) { @client.vcc_campaign_list() }

  it "clean up existing agents" do
    count_before = agents.count
    skip "No agents found" unless count_before > 0

    agents.each do |agent|
      @client.vcc_agent_del(agent["exten"])
    end

    agents = @client.vcc_agent_list()
    count_after = agents.count
    expect(count_after).to be < count_before
  end

  context "added agents" do
    before(:context) do
      @crm_ids = [ "1001", "crm_id_2345", "ABCDEF" ]
      @crm_ids.each do |crm_id|
        @client.vcc_agent_add(crm_id)
      end
    end

    let(:agents) { @client.vcc_agent_list() }

    it "list added agents" do
      crm_ids = agents.map { |agent| agent["crm_id"] }
      expect(crm_ids).to include(*@crm_ids)
    end


    it "do not list deleted agents" do
      agents.each do |agent|
        @client.vcc_agent_del(agent["exten"])
      end

      agents = @client.vcc_agent_list()
      crm_ids = agents.map { |agent| agent["crm_id"] }
      expect(crm_ids).not_to include(*@crm_ids)
    end
  end

  it "clean up existing campaigns" do
    count_before = campaigns.count
    skip "No campaigns found" unless count_before > 0

    campaigns.each do |campaign|
      @client.vcc_campaign_del(campaign["guid"])
    end

    campaigns = @client.vcc_campaign_list()
    count_after = campaigns.count
    expect(count_after).to be < count_before
  end

  context "added campaigns" do
    before(:context) do
      @campaign_names = %w(campaign01 CampaignX CAMPAIGN_N)
      @campaign_names.each do |name|
        @client.vcc_campaign_add(name)
      end
    end

    it "list added campaigns" do
      campaign_names = campaigns.map { |campaign| campaign["name"] }
      expect(campaign_names).to include(*@campaign_names)
    end

    it "do not list deleted campaigns" do
      campaigns.each do |campaign|
        @client.vcc_campaign_del(campaign["guid"])
      end

      campaigns = @client.vcc_campaign_list()
      campaign_names = campaigns.map { |campaign| campaign["name"] }
      expect(campaign_names).not_to include(*@campaign_names)
    end
  end

  context "within a campaign" do
    before(:context) do
      @campaign_guid = @client.vcc_campaign_add("Testing Campaign + Leads")
    end

    let(:leads) { @client.vcc_lead_list(@campaign_guid) }

    context "individual added leads" do
      before(:context) do
        @lead_phones = %w(14162223333 14164321234 14169998765)
        @lead_phones.each do |lead_phone|
          @client.vcc_lead_add(@campaign_guid, lead_phone, lead_phone)
        end
      end

      it "list added leads" do
        leads
        lead_phones = leads.map { |lead| lead["phone"] }
        expect(lead_phones).to include(*@lead_phones)
      end

      it "do not list deleted leads" do
        leads.each do |lead|
          @client.vcc_lead_del(lead["guid"])
        end

        leads = @client.vcc_lead_list(@campaign_guid)
        lead_phones = leads.map { |lead| lead["phone"] }
        expect(lead_phones).not_to include(*@lead_phones)
      end
    end

    context "bulk added leads" do
      before(:context) do
        @lead_phones = %w(14162332233 14163432124 16479769985 16479760000)
        @client.vcc_leads_add(@campaign_guid, @lead_phones, @lead_phones)
      end

      it "list added leads" do
        leads
        lead_phones = leads.map { |lead| lead["phone"] }
        expect(lead_phones).to include(*@lead_phones)
      end

      it "do not list deleted leads" do
        leads.each do |lead|
          @client.vcc_lead_del(lead["guid"])
        end

        leads = @client.vcc_lead_list(@campaign_guid)
        lead_phones = leads.map { |lead| lead["phone"] }
        expect(lead_phones).not_to include(*@lead_phones)
      end
    end

    after(:context) do
      @client.vcc_campaign_del(@campaign_guid)
    end
  end

end
