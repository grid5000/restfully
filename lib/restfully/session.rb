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
    attr_reader :base_url, :relative_root_uri, :logger, :connection, :root, :default_headers
    
    # TODO: use CacheableResource
    def initialize(base_url, options = {})
      options = options.symbolize_keys
      @base_url = base_url
      @relative_root_uri = options.delete(:relative_root_uri) || '/'
      @logger = options.delete(:logger) || NullLogger.new
      @default_headers = options.delete(:default_headers) || {'Accept' => 'application/json'}
      @connection = Restfully.adapter.new(@base_url, options)
      @root = Resource.new(URI.parse(@relative_root_uri), self)
      yield @root.load, self if block_given?
    end
    
    # TODO: inspect response headers to determine which methods are available
    def get(path, options = {})
      path = path.to_s
      options = options.symbolize_keys
      uri = URI.parse(base_url)
      path_uri = URI.parse(path)
      # if the given path is complete URL, forget the base_url, else append the path to the base_url
      unless path_uri.scheme.nil?
        uri = path_uri
      else  
        uri.path << path
      end
      request = HTTP::Request.new(uri, :headers => options.delete(:headers) || {}, :query => options.delete(:query) || {})
      request.add_headers(@default_headers) unless @default_headers.empty?
      logger.info "GET #{request.inspect}"
      response = connection.get(request)
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