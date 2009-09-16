require 'restfully/http/adapters/abstract_adapter'
require 'restclient'

module Restfully
  module HTTP
    module Adapters
      class RestClientAdapter < AbstractAdapter
        def initialize(base_url, options = {})
          super(base_url, options)
        end
        def get(request)
          begin
            resource = RestClient::Resource.new(request.uri.to_s, @options)
            response = resource.get(request.headers)
            headers = response.headers
            body = response.to_s
            status = headers.delete(:status)
          rescue RestClient::Exception => e
            body = e.response.body.to_s
            headers = e.response.to_hash
            status = headers.delete('status') || e.response.code
          end
          Response.new(status, headers, body)
        end
      end
    
    end
  end
end