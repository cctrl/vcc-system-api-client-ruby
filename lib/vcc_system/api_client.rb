require 'addressable/uri'
require 'faraday'
require 'nokogiri'
require 'json'
require 'colorize'
require 'logger'

require File.expand_path('config', File.dirname(__FILE__))
require File.expand_path('agent', File.dirname(__FILE__))
require File.expand_path('campaign', File.dirname(__FILE__))
require File.expand_path('lead', File.dirname(__FILE__))

module VCCSystem
  # TODO refactory execute/execute_post
  class APIClient
    attr_accessor :connection
    attr_accessor :scheme
    attr_accessor :host
    attr_accessor :port
    attr_accessor :path
    attr_accessor :debug
    attr_accessor :project_guid
    attr_accessor :caller_id
    attr_accessor :api_token
    attr_accessor :logger

    include Agent
    include Campaign
    include Lead

    def initialize(*args)
      options = Hash[(args.first || {}).map { |k,v| [k.to_sym,v] }]
      config = VCCSystem.config

      self.scheme = options[:scheme] || config.scheme
      self.host = options[:host] || config.host
      self.port = options[:port] || config.port
      self.path = options[:path] || config.path
      self.debug = options[:debug] || config.debug
      self.project_guid = options[:project_guid] || config.project_guid
      self.caller_id = options[:caller_id] || config.caller_id
      self.api_token = options[:api_token] || config.api_token
      self.logger = options[:logger] || Logger.new(STDOUT)
      self.logger.level = Logger::DEBUG if self.debug

      url = self.get_api_uri.normalize.to_s
      self.logger.debug "Connecting: #{url}".magenta

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
      self.logger.debug "Executing: #{method}".blue
      request_params = (params.first || {})
      request_params[:api_token] = self.api_token if self.api_token
      response = self.connection.post do |req|
        req.url "#{self.path}/#{method}.php"
        request_params.each { |k,v| req.params[k] = v }
      end
      self.logger.debug "Request(POST): #{response.env.url.to_s}".yellow
      self.logger.debug "Response: #{response.body}".cyan
      response
    end

    def execute(method, *params)
      self.logger.debug "Executing: #{method}".blue
      request_params = (params.first || {})
      request_params[:api_token] = self.api_token if self.api_token
      response = self.connection.get do |req|
        req.url "#{self.path}/#{method}.php"
        request_params.each { |k,v| req.params[k] = v }
      end
      self.logger.debug "Request(GET): #{response.env.url.to_s}".yellow
      self.logger.debug "Response: #{response.body}".cyan
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
      parsed = JSON.parse(response)
      if parsed.instance_of? Hash
        parsed = parsed.inject({}){ |memo,(k,v)| memo[k.to_sym] = v; memo }
      end
      parsed
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
