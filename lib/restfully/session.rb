require 'logger'
require 'uri'
require 'restclient'
require 'restclient/components'
require 'rack/cache'
require 'addressable/uri'

module Restfully
  class Session


    attr_accessor :logger, :uri
    attr_reader :config
    attr_writer :default_headers

    def initialize(options = {})
      @config = options.symbolize_keys
      @logger = @config.delete(:logger) || Logger.new(STDERR)

      # Read configuration from file:
      config_file = @config.delete(:configuration_file) || ENV['RESTFULLY_CONFIG']
      config_file = File.expand_path(config_file) if config_file
      if config_file && File.file?(config_file) && File.readable?(config_file)
        @logger.info "Using configuration file located at #{config_file}."
        @config = YAML.load_file(config_file).symbolize_keys.merge(@config)
      end

      # Require additional media-types:
      (@config[:require] || []).each do |r|
        @logger.info "Requiring #{r} media-type..."
        require "restfully/media_type/#{r.underscore}"
      end

      @config[:retry_on_error] ||= 5
      @config[:wait_before_retry] ||= 5

      # Compatibility with :base_uri parameter of Restfully <= 0.6
      @uri = @config.delete(:uri) || @config.delete(:base_uri)
      if @uri.nil? || @uri.empty?
        raise ArgumentError, "You must pass a :uri option."
      else
        @uri = Addressable::URI.parse(@uri)
      end

      default_headers.merge!(@config.delete(:default_headers) || {})

      disable RestClient::Rack::Compatibility
      authenticate(@config)
      setup_cache

      yield root, self if block_given?
    end

    def enable(rack, *args)
      logger.info "Enabling #{rack.inspect}."
      RestClient.enable rack, *args
    end

    def disable(rack, *args)
      logger.info "Disabling #{rack.inspect}."
      RestClient.disable rack, *args
    end

    def middleware
      RestClient.components.map{|(rack, args)| rack}
    end

    def authenticate(options = {})
      if options[:username]
        enable(
          Restfully::Rack::BasicAuth,
          options[:username],
          options[:password]
        )
      end
    end

    # Builds the complete URI, based on the given path and the session's uri
    def uri_to(path)
      Addressable::URI.join(uri.to_s, path.to_s)
    end

    def default_headers
      @default_headers ||= {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip, deflate'
      }
    end

    def root
      get(uri.path).load
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def head(path, options = {})
      transmit :head, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def get(path, options = {})
      transmit :get, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def post(path, body, options = {})
      options[:body] = body
      transmit :post, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def put(path, body, options = {})
      options[:body] = body
      transmit :put, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def delete(path, options = {})
      transmit :delete, path, options
    end

    # Build and execute the corresponding HTTP request,
    # then process the response.
    def transmit(method, path, options)
      request = HTTP::Request.new(self, method, path, options)
      response = request.execute!
      process(response, request)
    end

    # Process a Restfully::HTTP::Response.
    def process(response, request)
      case code=response.code
      when 200
        logger.debug "Building response..."
        Resource.new(self, response, request).build
      when 201,202
        logger.debug "Following redirection to: #{response.head['Location'].inspect}"
        get response.head['Location'], :head => request.head
      when 204
        true
      when 400..499
        raise HTTP::ClientError, error_message(request, response)
      when 502..504
        if res = request.retry!
          process(res, request)
        else
         raise(HTTP::ServerError, error_message(request, response))
       end
      when 500, 501
        raise HTTP::ServerError, error_message(request, response)
      else
        raise Error, "Restfully does not handle code #{code.inspect}."
      end
    end

    protected
    def setup_cache
      enable ::Rack::Cache, :verbose => (logger.level <= Logger::INFO)
    end

    def error_message(request, response)
      msg = "Encountered error #{response.code} on #{request.method.upcase} #{request.uri}"
      msg += " --- #{response.body[0..200]}" unless response.body.empty?
    end

  end

end
