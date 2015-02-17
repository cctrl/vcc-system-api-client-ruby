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

    def initialize(project_guid, *args)
      options = Hash[(args.first || {}).map { |k,v| [k.to_sym,v] }]

      self.scheme = options[:scheme] || 'https'
      self.host = options[:host] || 'nbvcc.giisystems.com'
      self.port = options[:port] || 443
      self.path = options[:path] || '/vcc'
      self.debug = options[:debug] || false
      self.project_guid = project_guid

      puts "Connecting to #{self.get_api_url}" if self.debug
      self.connection = Faraday.new(url: self.get_api_url) do |faraday|
        faraday.ssl.verify = false
        faraday.adapter Faraday.default_adapter
      end
    end

    # <root><status>4</status><response><item></item></response></root>
    def vcc_agent_add(crm_id)
      response = self.execute __method__, project_guid: self.project_guid, crm_id: crm_id
      extract = { status: "//root/status", item: "//root/response/item" }

      begin
        parsed = self.parse_response!(response, extract, :xml)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end

      case parsed[:status].to_i
      when 0
        parsed[:item]
      when 1
        raise "Failed to add agent"
      else
        raise "Invalid status (#{parsed[:status]})"
      end
    end

    def vcc_lead_list
      self.execute __method__, project_guid: self.project_guid
    end

    def vcc_project_list
      response = self.execute __method__
      extract = %w(created name guid active dial_trunk reference_id contact
                   email phone web campaigns_max agents_max expired features)
      begin
        self.parse_response!(response, extract, :json)
      rescue RuntimeError => e
        raise "Invalid response for #{__method__} (#{e.message})"
      end
    end

    protected

    def get_api_url
      @api_url ||= Addressable::URI.new(
        :scheme => self.scheme,
        :host => self.host,
        :port => self.port
      ).normalize.to_s
    end

    def execute(method, *params)
      response = self.connection.get do |req|
        req.url "#{self.path}/#{method}.php"
        (params.first || {}).each { |k,v| req.params[k] = v }
      end
      puts "request #{response.env.url.to_s}" if self.debug
      puts "response >>>\n#{response.body}\n<<<" if self.debug
      response
    end

    def parse_xml_response(response, extract)
      raise "Invalid extract" unless extract.kind_of? Hash

      xml = Nokogiri::XML(response)
      parsed = {}

      extract.each do |k,path|
        node = xml.xpath(path)
        count = node.count
        if count == 1
          parsed[k] = node.first.content
        elsif count > 1
          parsed[k] = node.map { |j| j.content }
        else
          parsed[k] = nil
        end
      end

      parsed
    end

    def parse_json_response(response, extract)
      raise "Invalid extract" unless extract.kind_of? Array

      json = JSON.parse response
      parsed = []

      case json
      when Array
        json.each do |j|
          next unless j.kind_of? Hash
          h_parsed = j.select { |k| extract.include? k.to_s }
          parsed << h_parsed unless h_parsed.empty?
        end
      when Hash
        h_parsed = json.select { |k| extract.include? k.to_s }
        parsed << h_parsed unless h_parsed.empty?
      else
        parsed << json
      end

      parsed
    end

    def parse_response!(response, extract, format=:xml)
      raise "Invalid response" unless response.instance_of? Faraday::Response
      raise "Invalid response status (#{response.status})" unless response.status == 200

      case format.to_s.to_sym
      when :xml
        parse_xml_response(response.body, extract)
      when :json
        parse_json_response(response.body, extract)
      else
        raise "Invalid format"
      end
    end

  end
end
