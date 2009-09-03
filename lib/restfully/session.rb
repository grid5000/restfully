require 'uri'
require 'logger'
require 'restclient'

module Restfully
  class Error < StandardError; end
  class HTTPError < Error; end
  class NullLogger
    def method_missing(method, *args)
      nil
    end
  end
  class Session
    include Parsing
    attr_reader :base_url, :logger, :connection, :root
    
    # TODO: use CacheableResource
    def initialize(base_url, options = {})
      @base_url = base_url
      @root = options['root'] || '/'
      @logger = options['logger'] || NullLogger.new 
      @user = options['user']
      @password = options['password']
      # TODO: generalize
      # @connection = Patron::Session.new
      # @connection.timeout = 10
      # @connection.base_url = base_url
      # @connection.headers['User-Agent'] = 'restfully'
      # @connection.insecure = true
      # @connection.username = @user
      # @connection.password = @password      
      @connection = RestClient::Resource.new(base_url || '', :user => @user, :password => @password)
      yield Resource.new(root, self).load, self if block_given?
    end
    
    # TODO: uniformize headers hash (should accept symbols and strings in any capitalization format)
    # TODO: inspect response headers to determine which methods are available
    def get(path, headers = {})
      headers = headers.symbolize_keys
      headers[:accept] ||= 'application/json'
      logger.info "GET #{path} #{headers.inspect}"
      # TODO: should be able to choose HTTP lib to use, so we must provide abstract interface for HTTP handlers
      api = path.empty? ? connection : connection[path]
      response = api.get(headers)
      parse response#, :content_type => response.headers['Content-Type']
      # response = connection.get(path, headers)
      # logger.info response.headers
      # logger.info response.status
      # if (200..300).include?(response.status)
        # parse response.body, :content_type => response.headers['Content-Type']
      # else
        # TODO: better error management ;-)
        # raise HTTPError.new("Error: #{response.status}")
      # end
    end
  
    # TODO: add other HTTP methods
  end
end