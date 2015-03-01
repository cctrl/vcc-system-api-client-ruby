require 'addressable/uri'
require 'faraday'
require 'nokogiri'
require 'json'
require 'colorize'

require File.expand_path('agent', File.dirname(__FILE__))
require File.expand_path('campaign', File.dirname(__FILE__))
require File.expand_path('lead', File.dirname(__FILE__))

module VCCSystem
  class APIClient
    attr_accessor :connection
    attr_accessor :scheme
    attr_accessor :host
    attr_accessor :port
    attr_accessor :path
    attr_accessor :debug
    attr_accessor :project_guid

    include Agent
    include Campaign
    include Lead

    def initialize(project_guid, *args)
      options = Hash[(args.first || {}).map { |k,v| [k.to_sym,v] }]

      self.scheme = options[:scheme] || 'https'
      self.host = options[:host] || 'nbvcc.giisystems.com'
      self.port = options[:port] || 443
      self.path = options[:path] || '/vcc'
      self.debug = options[:debug] || false
      self.project_guid = project_guid

      url = self.get_api_uri.normalize.to_s
      puts "Connecting:\n\t#{url}".magenta if self.debug

      self.connection = Faraday.new(url: url) do |faraday|
        faraday.ssl.verify = false
        faraday.adapter Faraday.default_adapter
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

    def execute_post(method, *params)
      puts "Executing:\n\t#{method}".blue if self.debug
      response = self.connection.post do |req|
        req.url "#{self.path}/#{method}.php"
        (params.first || {}).each { |k,v| req.params[k] = v }
      end
      puts "Request(POST):\n\t#{response.env.url.to_s}".yellow if self.debug
      puts "Response:\n\t#{response.body}\n".cyan if self.debug
      response
    end

    def execute(method, *params)
      puts "Executing:\n\t#{method}".blue if self.debug
      response = self.connection.get do |req|
        req.url "#{self.path}/#{method}.php"
        (params.first || {}).each { |k,v| req.params[k] = v }
      end
      puts "Request(GET):\n\t#{response.env.url.to_s}".yellow if self.debug
      puts "Response:\n\t#{response.body}\n".cyan if self.debug
      response
    end

    def extract_xml_element_content(element)
      element = element.first   if element.instance_of? Array
      element = element.first   if element.instance_of? Nokogiri::XML::NodeSet
      element = element.content if element.instance_of? Nokogiri::XML::Element
      element
    end

    def extract_xml_item(item, extract=nil)
      if extract.instance_of? Array
        Hash[extract.map { |k| [ k, self.extract_xml_element_content(item.xpath(k)) ] }]
      else
        self.extract_xml_element_content(item.content)
      end
    end

    def parse_xml_response(response, extract)
      xml = Nokogiri::XML(response)
      parsed = {}
      extract ||= {}

      status = xml.xpath("//root/status")
      parsed[:status] = status.first.content if status.count == 1

      items = xml.xpath("//root/response/item")
      parsed[:items] = items.map { |item| self.extract_xml_item(item, extract[:item]) }

      # optional result parsing
      leads = xml.xpath("//root/lead")
      extracted_leads = leads.map { |lead| self.extract_xml_item(lead) } || []
      parsed[:leads] = extracted_leads.map { |lead| Hash[(extract[:lead] || []).zip lead.to_s.split(',')] } if extracted_leads.length > 0

      parsed
    end

    def parse_json_response(response)
      JSON.parse response
    end

    def parse_response!(response, format=:json, extract=nil)
      raise "Invalid response" unless response.instance_of? Faraday::Response
      raise "Invalid response status (#{response.status})" unless response.status == 200

      case format.to_sym
      when :json
        parse_json_response(response.body)
      when :xml
        parse_xml_response(response.body, extract)
      else
        raise "Invalid format (#{format})"
      end
    end

  end
end
