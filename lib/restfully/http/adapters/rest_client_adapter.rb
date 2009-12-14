require 'restfully/http/adapters/abstract_adapter'
require 'restclient'

module Restfully
  module HTTP
    module Adapters
      class RestClientAdapter < AbstractAdapter
        
        def initialize(base_uri, options = {})
          super(base_uri, options)
          @options[:user] = @options.delete(:username)
        end # def initialize
        
        def head(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.head(request.headers)
          end
        end # def get
        
        def get(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.get(request.headers)
          end
        end # def get
        

        def delete(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.delete(request.headers)
          end
        end # def delete
        
        def post(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.post(request.raw_body, request.headers)
          end
        end # def post
        
        protected
        def in_order_to_get_the_response_to(request, &block)
          begin
            resource = RestClient::Resource.new(request.uri.to_s, @options)
            response = block.call(resource)
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
        end # def in_order_to_get_the_response_to
        
      end
    
    end
  end
end