require 'active_support/configurable'

module VCCSystem
  def self.configure(&block)
    yield @config ||= VCCSystem::Configuration.new
  end

  def self.config
    @config
  end

  class Configuration
    include ActiveSupport::Configurable
    config_accessor :scheme
    config_accessor :host
    config_accessor :port
    config_accessor :path
    config_accessor :debug
    config_accessor :project_guid
    config_accessor :caller_id
    config_accessor :api_token

    def param_name
      config.param_name.respond_to?(:call) ? config.param_name.call : config.param_name
    end

    writer, line = 'def param_name=(value); config.param_name = value; end', __LINE__
    singleton_class.class_eval writer, __FILE__, line
    class_eval writer, __FILE__, line
  end

  configure do |config|
    config.scheme = 'https'
    config.host = 'vcc.giisystems.com'
    config.port = 443
    config.path = '/vcc'
    config.debug = false
  end
end
