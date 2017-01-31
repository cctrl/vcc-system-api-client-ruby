module VCCSystem
  module Lead

    LEAD_ADD_ERRORS = {
      "1" => "Invalid campaign GUID",
      "2" => "Invalid phone number format",
      "3" => "System error"
    }

    def vcc_lead_add(campaign_guid, phone, reference_id)
      phone = phone.to_s.gsub(/[^\d]/, '')
      raise "Phone number format required: 1XXXXXXXXXX" unless phone.match(/^[\d]{11}$/)

      response = self.execute __method__, account_id: self.account_id,
        campaign_id: campaign_guid,
        phone: phone,
        reference_id: reference_id

      parsed = begin
        self.parse_response!(response, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:items].first if parsed[:status] == "0"

      raise(LEAD_ADD_ERRORS[(parsed[:status])] || "Failed (status: #{parsed[:status]})")
    end

    # https://nbvcc.giisystems.com/vcc/vcc_leads_add.php?campaign_guid=abcd&phone[]=123&reference_id[]=1&phone[]=234&reference_id[]=2
    def vcc_leads_add(campaign_guid, phones, reference_ids)
      phones ||= []
      reference_ids ||= []
      raise "phones and reference_ids should have same size" unless phones.length == reference_ids.length
      count = phones.length

      phones = phones.map{ |phone| phone.to_s.gsub(/[^\d]/, '') }

      response = self.execute_post __method__, account_id: self.account_id,
        campaign_id: campaign_guid,
        phone: phones,
        reference_id: reference_ids

      parsed = begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      return parsed[:status]
    end

    def vcc_lead_del(lead_guid, campaign_guid)
      response = self.execute __method__, account_id: self.account_id,
        guid: lead_guid, campaign_guid: campaign_guid

      parsed = begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      parsed[:status] == "0" || raise("Failed (status: #{parsed[:status]})")
    end

    def vcc_lead_status(campaign_guid)
      response = self.execute __method__, account_id: self.account_id,
        campaign_id: campaign_guid

      begin
        self.parse_response!(response)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end
    end

  end
end
