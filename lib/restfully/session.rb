require 'uri'
require 'logger'
require 'restfully/parsing'

module Restfully
  class NullLogger
    def method_missing(method, *args)
      nil
    end
  end
  class Session
    include Parsing
    attr_reader :base_uri, :root_path, :logger, :connection, :root, :default_headers
    
    # TODO: use CacheableResource
    def initialize(base_uri, options = {})
      options = options.symbolize_keys
      @base_uri = base_uri
      @root_path = options.delete(:root_path) || '/'
      @logger = options.delete(:logger) || NullLogger.new
      @default_headers = options.delete(:default_headers) || {'Accept' => 'application/json'}
      @connection = Restfully.adapter.new(@base_uri, options.merge(:logger => @logger))
      @root = Resource.new(URI.parse(@root_path), self)
      yield @root.load, self if block_given?
    end
    
    # TODO: inspect response headers to determine which methods are available
    def get(path, options = {})
      path = path.to_s
      options = options.symbolize_keys
      uri = URI.parse(base_uri)
      path_uri = URI.parse(path)
      # if the given path is complete URL, forget the base_uri, else append the path to the base_uri
      unless path_uri.scheme.nil?
        uri = path_uri
      else  
        uri.path << path
      end
      request = HTTP::Request.new(uri, :headers => options.delete(:headers) || {}, :query => options.delete(:query) || {})
      request.add_headers(@default_headers) unless @default_headers.empty?
      logger.info "GET #{request.uri}, #{request.headers.inspect}"
      response = connection.get(request)
      logger.debug "Response to GET #{request.uri}: #{response.headers.inspect}"
      response = deal_with_eventual_errors(response, request)
    end
    
    protected
    def deal_with_eventual_errors(response, request)
      case response.status
      when 400..499
        # should retry on 406 with another Accept header
        raise Restfully::HTTP::ClientError, response
      when 500..599  
        raise Restfully::HTTP::ServerError, response
      else
        response
      end
    end

  end
end