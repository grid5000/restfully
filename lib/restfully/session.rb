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
    include Parsing, HTTP::Headers
    attr_reader :base_uri, :logger, :connection, :default_headers
    
    def initialize(options = {})
      options = options.symbolize_keys
      if (config_filename = options.delete(:configuration_file)) && File.exists?(File.expand_path(config_filename))
        config = YAML.load_file(File.expand_path(config_filename)).symbolize_keys
        options.merge!(config)
      end
      @base_uri               =   URI.parse(options.delete(:base_uri) || "http://localhost:8888") rescue nil
      raise ArgumentError.new("#{@base_uri} is not a valid URI") if @base_uri.nil? || @base_uri.scheme !~ /^http/i
      @logger                 =   options.delete(:logger) || NullLogger.new
      @logger.level           =   options.delete(:verbose) ? Logger::DEBUG : @logger.level
      user_default_headers    =   sanitize_http_headers(options.delete(:default_headers) || {})
      @default_headers        =   {'User-Agent' => "Restfully/#{Restfully::VERSION}", 'Accept' => 'application/json'}.merge(user_default_headers)
      @connection             =   Restfully.adapter.new(base_uri.to_s, options.merge(:logger => logger))
      @root                   =   Resource.new(@base_uri, self)
      yield @root.load, self if block_given?
    end
    
    # returns the root resource
    def root
      @root.load
    end
    
    # returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def head(path, options = {})
      options = options.symbolize_keys
      transmit :head, HTTP::Request.new(uri_for(path), :headers => options.delete(:headers), :query => options.delete(:query))
    end
    
    # returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def get(path, options = {})
      options = options.symbolize_keys
      transmit :get, HTTP::Request.new(uri_for(path), :headers => options.delete(:headers), :query => options.delete(:query))
    end
    
    # returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def post(path, body, options = {})
      options = options.symbolize_keys
      uri = uri_for(path)
      transmit :post, HTTP::Request.new(uri_for(path), :body => body, :headers => options.delete(:headers), :query => options.delete(:query))
    end
    
    # returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def put(path, body, options = {})
      options = options.symbolize_keys
      uri = uri_for(path)
      transmit :put, HTTP::Request.new(uri_for(path), :body => body, :headers => options.delete(:headers), :query => options.delete(:query))
    end
    
    # returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def delete(path, options = {})
      options = options.symbolize_keys
      transmit :delete, HTTP::Request.new(uri_for(path), :headers => options.delete(:headers), :query => options.delete(:query))
    end
    
    # builds the complete URI, based on the given path and the session's base_uri
    def uri_for(path)
      URI.join(base_uri.to_s, path.to_s)
    end
    
    protected
    def transmit(method, request)
      default_headers.each do |header, value|
        request.headers[header] ||= value
      end
      response = connection.send(method.to_sym, request)
      response = deal_with_eventual_errors(response, request)
    end
    
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