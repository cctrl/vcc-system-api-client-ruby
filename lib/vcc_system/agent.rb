module VCCSystem
  module Agent

    AGENT_ADD_ERRORS = {
      "2" => "Permission denied",
      "4" => "Number of agents exceeded"
    }

    def vcc_agent_add(crm_id)
      response = self.execute __method__, project_guid: self.project_guid,
        crm_id: crm_id

      parsed = begin
        self.parse_response!(response, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:items].first if parsed[:status] == "0"

      raise(AGENT_ADD_ERRORS[(parsed[:status])] || "Failed (status: #{parsed[:status]})")
    end

    def vcc_agent_del(agent_exten)
      response = self.execute __method__, project_guid: self.project_guid,
        agent_exten: agent_exten

      parsed = begin
        self.parse_response!(response, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      parsed[:status] == "0" || raise("Failed (status: #{parsed[:status]})")
    end

    def vcc_agent_list
      response = self.execute __method__, project_guid: self.project_guid
      extract = { item: %w(
        exten crmname agent_type project_guid crm_id project_name
      ) }

      parsed = begin
        self.parse_response!(response, :xml, extract)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:items] if parsed[:status] == "0"

      raise "Failed (status: #{parsed[:status]})"
    end

    def vcc_agent_start(agent, campaign, crm)
      uri = self.get_api_uri
      uri.path = "#{self.path}/#{__method__}.php"
      uri.query_values = {
        agent: agent, campaign: campaign, project: self.project_guid,
        vcc: self.host, crm: crm
      }
      uri.normalize.to_s
    end

  end
end
