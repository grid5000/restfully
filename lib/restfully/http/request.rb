require 'uri'
module Restfully
  module HTTP
    
    class Request
      include Headers, Restfully::Parsing
      attr_reader :headers, :uri
      attr_accessor :retries
      
      def initialize(url, options = {})
        options = options.symbolize_keys
        @uri = url.kind_of?(URI) ? url : URI.parse(url)
        @headers = sanitize_http_headers(options.delete(:headers) || {})
        if query = options.delete(:query)
          @uri.query = [@uri.query, query.to_params].compact.join("&")
        end
        @body = options.delete(:body)
        @retries = 0
      end
      
      def body
        if @body.kind_of?(String)
          @unserialized_body ||= unserialize(@body, :content_type => @headers['Content-Type'])
        else
          @body
        end
      end
      
      def raw_body
        if @body.kind_of?(String)
          @body
        else
          @serialized_body ||= serialize(@body, :content_type => @headers['Content-Type'])
        end
      end
      
      def add_headers(headers = {})
        @headers.merge!(sanitize_http_headers(headers || {}))
      end
    end
  end
end