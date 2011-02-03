require 'restfully/http/adapters/abstract_adapter'
require 'restclient'

module Restfully
  module HTTP
    module Adapters
      class RestClientAdapter < AbstractAdapter
        
        def initialize(base_uri, options = {})
          super(base_uri, options)
          @options[:user] = @options.delete(:username)
          RestClient.log = logger
        end # def initialize
        
        def head(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.head(convert_header_keys_into_symbols(request.headers))
          end
        end # def head
        
        def get(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.get(convert_header_keys_into_symbols(request.headers))
          end
        end # def get
        
        def delete(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.delete(convert_header_keys_into_symbols(request.headers))
          end
        end # def delete
        
        def put(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.put(request.raw_body, convert_header_keys_into_symbols(request.headers))
          end
        end # def put
        
        def post(request)
          in_order_to_get_the_response_to(request) do |resource|
            resource.post(request.raw_body, convert_header_keys_into_symbols(request.headers))
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
            body = e.response.to_s
            headers = e.response.headers rescue {}
            status = e.http_code
          end
          Response.new(status, headers, body)
        end # def in_order_to_get_the_response_to
        
        # there is a bug in RestClient, when passing headers whose keys are string that are already defined as default headers, they get overwritten.
        def convert_header_keys_into_symbols(headers)
          headers.inject({}) do |final, (key,value)|
            key = key.to_s.gsub(/-/, "_").downcase.to_sym
            final[key] = value
            final
          end
        end # def convert_header_keys_into_symbols
        
      end
    
    end
  end
end