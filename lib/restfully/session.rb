require 'uri'
require 'logger'
require 'restclient'

module Restfully
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
      @connection = RestClient::Resource.new(base_url || '', :user => @user, :password => @password)
      yield Resource.new(root, self).load, self if block_given?
    end
    
    # TODO: uniformize headers hash (should accept symbols and strings in any capitalization format)
    # TODO: inspect response headers to determine which methods are available
    def get(path, headers = {:accept => 'application/json'})
      logger.info "GET #{path} #{headers.inspect}"
      # TODO: should be able to choose HTTP lib to use, so we must provide abstract interface for HTTP handlers
      api = path.empty? ? connection : connection[path]
      response = api.get(headers)
      parse response
    end
  
    # TODO: add other HTTP methods
  end
end