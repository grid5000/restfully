require 'uri'
module Restfully
  module HTTP
    class Request
      include Headers
      attr_reader :headers, :body, :uri
      attr_accessor :retries
      def initialize(url, options = {})
        options = options.symbolize_keys
        @uri = url.kind_of?(URI) ? url : URI.parse(url)
        @headers = sanitize_http_headers(options.delete(:headers) || {})
        if query = options.delete(:query)
          @uri.query = [@uri.query, query.to_params].compact.join("&")
        end
        @body = body
        @retries = 0
      end
      
      def add_headers(headers = {})
        @headers.merge!(sanitize_http_headers(headers || {}))
      end
    end
  end
end