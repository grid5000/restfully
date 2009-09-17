require 'restfully/http/adapters/abstract_adapter'
require 'restclient'

module Restfully
  module HTTP
    module Adapters
      class RestClientAdapter < AbstractAdapter
        def initialize(base_uri, options = {})
          super(base_uri, options)
          @options[:user] = @options.delete(:username)
        end
        def get(request)
          begin
            resource = RestClient::Resource.new(request.uri.to_s, @options)
            response = resource.get(request.headers)
            headers = response.headers
            body = response.to_s
            headers.delete(:status)
            status = response.code
          rescue RestClient::ExceptionWithResponse => e
            body = e.http_body
            headers = e.response.to_hash
            status = e.http_code
          end
          Response.new(status, headers, body)
        end
      end
    
    end
  end
end