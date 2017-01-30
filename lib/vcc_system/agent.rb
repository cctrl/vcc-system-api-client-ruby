module VCCSystem
  module Agent

    AGENT_ADD_ERRORS = {
      "2" => "Permission denied",
      "4" => "Number of agents exceeded"
    }

    def vcc_agent_add(crm_id)
      response = self.execute __method__, account_id: self.account_id,
        crm_id: crm_id

      parsed = begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      byebug
      return parsed[:items].first if parsed[:status] == "0"

      raise(AGENT_ADD_ERRORS[(parsed[:status])] || "Failed (status: #{parsed[:status]})")
    end

    def vcc_agent_del(agent_exten)
      response = self.execute __method__, account_id: self.account_id,
        agent_exten: agent_exten

      parsed = begin
        self.parse_response!(response, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      parsed[:status] == "0" || raise("Failed (status: #{parsed[:status]})")
    end

    def vcc_agent_list
      response = self.execute __method__, account_id: self.account_id
      extract = { item: %w(
        exten crmname agent_type account_id crm_id project_name
      ) }

      parsed = begin
        self.parse_response!(response, :json, extract)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end
    end

    def vcc_agent_start(agent, campaign, crm)
      uri = self.get_api_uri
      uri.path = "#{self.path}/#{__method__}.php"
      uri.query_values = {
        account_id: self.account_id,
        agent: agent,
        campaign_id: campaign,
        project: self.account_id,
        vcc: self.host,
        crm: crm
      }
      uri.normalize.to_s
    end

    def vcc_agent_proxy
      uri = self.get_api_uri
      uri.path = "#{self.path}/proxy.html"
      uri.normalize.to_s
    end

  end
end
