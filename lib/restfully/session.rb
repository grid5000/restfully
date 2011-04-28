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

      @uri = @config.delete(:uri)
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

    # Build and send the corresponding HTTP request, then process the response
    def transmit(method, path, options)
      request = HTTP::Request.new(self, method, path, options)

      response = execute(request)

      process(response, request)
    end

    def execute(request)
      resource = RestClient::Resource.new(
        request.uri.to_s,
        :headers => request.head
      )

      logger.debug request.inspect
      code, head, body = resource.send(request.method, request.body || {})

      response = Restfully::HTTP::Response.new(self, code, head, body)
    end

    # Process a Restfully::HTTP::Response.
    def process(response, request)
      case code=response.code
      when 200
        Resource.new(self, response, request).build
      when 201,202
        get response.head['Location'], :head => request.head
      when 204
        true
      when 400..499
        msg = "Encountered error #{code} on #{request.method.upcase} #{request.uri}"
        msg += " --- #{response.body[0..200]}" unless response.body.empty?
        raise HTTP::ClientError, msg
      when 500..599
        # when 503, sleep 5, request.retry
        msg = "Encountered error #{code} on #{request.method.upcase} #{request.uri}"
        msg += " --- #{response.body[0..200]}" unless response.body.empty?
        raise HTTP::ServerError, msg
      else
        raise Error, "Restfully does not handle code #{code.inspect}."
      end
    end

    protected
    def setup_cache
      enable ::Rack::Cache, :verbose => (logger.level < Logger::INFO)
    end

  end

end
