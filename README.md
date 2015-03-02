# VCC System API Client (Ruby)

```
gem 'vcc-system-api-client', :git => 'git://github.com/lememora/vcc-system-api-client-ruby.git'
```

```
require 'vcc_system/api_client'
```

New client:

```
VCCSystem.config.project_guid = 'a0b1c2d3-e4f5-a0b1-c2d3-e4f5a0b1c2d3'
@client = VCCSystem::APIClient.new
```

## Workflow A: Storing VCC ids

Add agent:

```
crm_id = 'Agent_1001'
agent_id = @client.vcc_agent_add crm_id
```

Add campaign:

```
campaign_name = "My New Campaign"
campaign_guid = @client.vcc_campaign_add campaign_name
```

Add lead:

```
phone = "14160000000"
reference_id = "Lead_2001"
lead_guid = @client.vcc_lead_add(campaign_guid, phone, reference_id)
```

Start agent:

```
proxy_url = "http://myhost.com/path/to/proxy.html"
proxy_path = proxy_url.sub(/^.*:\/\//, '').sub(/\/proxy.html$/, '') # myhost.com/path/to
agent_url = @client.vcc_agent_start(agent_id, campaign_guid, proxy_path)
```

Delete:

```
@client.vcc_lead_del(lead_guid)
@client.vcc_campaign_del(campaign_guid)
@client.vcc_agent_del(agent_id)
```

### Workflow B: Without storing VCC ids

Add agent:

```
crm_id = 'Agent_1001'
@client.vcc_agent_add crm_id
```

Retrieve agent:

```
agent_id = @client.vcc_agent_list.select { |a| a["crmname"] = crm_id }.first["exten"]
```

Add campaign:

```
campaign_name = "My New Campaign"
@client.vcc_campaign_add campaign_name
```

Retrieve campaign:

```
campaign_guid = @client.vcc_campaign_list.select { |c| c["name"] = campaign_name }.first["guid"]
```

Add lead:

```
phone = "14160000000"
reference_id = "Lead_2001"
@client.vcc_lead_add(campaign_guid, phone, reference_id)
```

Retrieve lead:

```
lead_guid = @client.vcc_lead_list(campaign_guid).select { |l| l["reference"] = reference_id }.first["guid"]
```
