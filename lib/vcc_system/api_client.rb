require 'addressable/uri'
require 'faraday'
require 'nokogiri'
require 'json'

module VCCSystem
  class APIClient
    attr_accessor :connection
    attr_accessor :scheme
    attr_accessor :host
    attr_accessor :port
    attr_accessor :path
    attr_accessor :debug
    attr_accessor :project_guid

    AGENT_ADD_ERRORS = {
      "1" => "Failed to add agent",
      "2" => "Permission denied",
      "4" => "Number of agents exceeded"
    }

    AGENT_DEL_ERRORS = {
      "1" => "Failed to delete agent"
    }

    def initialize(project_guid, *args)
      options = Hash[(args.first || {}).map { |k,v| [k.to_sym,v] }]

      self.scheme = options[:scheme] || 'https'
      self.host = options[:host] || 'nbvcc.giisystems.com'
      self.port = options[:port] || 443
      self.path = options[:path] || '/vcc'
      self.debug = options[:debug] || false
      self.project_guid = project_guid

      url = self.get_api_uri.normalize.to_s
      puts "Connecting:\n\t#{url}" if self.debug

      self.connection = Faraday.new(url: url) do |faraday|
        faraday.ssl.verify = false
        faraday.adapter Faraday.default_adapter
      end
    end

    def vcc_agent_add(crm_id)
      response = self.execute __method__, project_guid: self.project_guid, crm_id: crm_id

      parsed = begin
        self.parse_response!(response, nil, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      if parsed[:status] == "0"
        parsed[:items].first
      else
        raise AGENT_ADD_ERRORS[(parsed[:status])] || "Invalid status (#{parsed[:status]})"
      end
    end

    def vcc_agent_list
      response = self.execute __method__, project_guid: self.project_guid
      extract = { item: %w(exten crmname agent_type project_guid crm_id project_name) }

      parsed = begin
        self.parse_response!(response, extract, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      if parsed[:status] == "0"
        parsed[:items]
      else
        raise "Invalid status (#{parsed[:status]})"
      end
    end

    def vcc_agent_del(agent_exten)
      response = self.execute __method__, project_guid: self.project_guid, agent_exten: agent_exten

      parsed = begin
        self.parse_response!(response, nil, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      if parsed[:status] == "0"
        true
      else
        raise AGENT_DEL_ERRORS[(parsed[:status])] || "Invalid status (#{parsed[:status]})"
      end
    end

    protected

    def get_api_uri
      @api_uri ||= Addressable::URI.new(
        :scheme => self.scheme,
        :host => self.host,
        :port => self.port
      )
    end

    def execute(method, *params)
      puts "Executing:\n\t#{method}" if self.debug
      response = self.connection.get do |req|
        req.url "#{self.path}/#{method}.php"
        (params.first || {}).each { |k,v| req.params[k] = v }
      end
      puts "Request:\n\t#{response.env.url.to_s}" if self.debug
      puts "Response:\n\t#{response.body}\n" if self.debug
      response
    end

    def extract_xml_element_content(element)
      element = element.first if element.instance_of? Array
      element = element.first if element.instance_of? Nokogiri::XML::NodeSet
      return unless element.instance_of? Nokogiri::XML::Element
      element.content
    end

    def extract_xml_item(item, extract)
      if extract.instance_of? Array
        Hash[extract.map { |k| [ k, self.extract_xml_element_content(item.xpath(k)) ] }]
      else
        self.extract_xml_element_content(item.content)
      end
    end

    def parse_xml_response(response, extract)
      xml = Nokogiri::XML(response)
      parsed = {}

      status = xml.xpath("//root/status")
      if status.count == 1
        parsed[:status] = status.first.content
      end

      items = xml.xpath("//root/response/item")
      extract_item = extract.instance_of?(Hash) ? extract[:item] : nil

      parsed[:items] = items.map { |item| self.extract_xml_item(item, extract_item) }

      parsed
    end

    def parse_json_response(response, extract)
      JSON.parse response
    end

    def parse_response!(response, extract, format=:xml)
      raise "Invalid response" unless response.instance_of? Faraday::Response
      raise "Invalid response status (#{response.status})" unless response.status == 200

      case format.to_sym
      when :xml
        parse_xml_response(response.body, extract)
      when :json
        parse_json_response(response.body, extract)
      else
        raise "Invalid format (#{format})"
      end
    end

  end
end
