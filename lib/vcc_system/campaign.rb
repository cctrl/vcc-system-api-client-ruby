module VCCSystem
  module Campaign

    CAMPAIGN_TYPE_OUTBOUND = 1

    CAMPAIGN_ADD_ERRORS = {
      "2" => "Invalid project",
      "3" => "Invalid type",
      "7" => "Campaign name must be set",
      "8" => "Number of campaigns exceeded"
    }

    def vcc_campaign_add(name)
      response = self.execute __method__, project_guid: self.project_guid,
        name: name,
        campaign_type: CAMPAIGN_TYPE_OUTBOUND,
        dial_ratio: 1

      parsed = begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:campaign_guid] if parsed[:status] == "0"

      raise(CAMPAIGN_ADD_ERRORS[(parsed[:status])] || "Failed (status: #{parsed[:status]})")
    end

    def vcc_campaign_del(guid)
      response = self.execute __method__, project_guid: self.project_guid,
        guid: guid

      parsed = begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      parsed[:status] == "0" || raise("Failed (status: #{parsed[:status]})")
    end

    def vcc_campaign_list
      response = self.execute __method__, project_guid: self.project_guid
      extract = { item: %w(
        guid dt name lt_bucket order project_guid campaign_type incoming_number
        redial_id daytime_id trg_id expire_leads callerid_number dial_ratio
        billing script ext_group_type amd_on project_name dial_ratio_max
        dial_mode ext_group_id ext_group_name
      ) }

      parsed = begin
        self.parse_response!(response, :xml, extract)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:items] if parsed[:status] == "0"

      raise "Failed (status: #{parsed[:status]})"
    end

  end
end
