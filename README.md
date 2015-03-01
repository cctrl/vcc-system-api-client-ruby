# VCC System API Client (Ruby)

```
gem install vcc-system-api-client
```

```
require 'vcc_system/api_client'

project_guid = 'a0b1c2d3-e4f5-a0b1-c2d3-e4f5a0b1c2d3'
@client = VCCSystem::APIClient.new project_guid

# add agent
crm_id = 'Agent_1001'
agent_guid = @client.vcc_agent_add crm_id

# add campaign
campaign_name = "My New Campaign"
campaign_guid = @client.vcc_campaign_add campaign_name

# add lead
phone = "14160000000"
reference_id = "Lead_2001"
lead_guid = @client.vcc_lead_add(campaign_guid, phone, reference_id)

# start agent
proxy_url = "http://myhost.com/path/to/proxy.html"
proxy_path = proxy_url.sub(/^.*:\/\//, '').sub(/\/proxy.html$/, '') # myhost.com/path/to
agent_url = @client.vcc_agent_start(agent_guid, campaign_guid, proxy_path)

# delete
@client.vcc_lead_del(lead_guid)
@client.vcc_campaign_del(campaign_guid)
@client.vcc_agent_del(agent_guid)
```
