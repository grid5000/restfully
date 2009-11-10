module Restfully
  module HTTP
    # Container for an HTTP Response. Has <tt>status</tt>, <tt>headers</tt> and <tt>body</tt> properties.
    class Response
      include Headers, Restfully::Parsing
      attr_reader :status, :headers
      
      # <tt>body</tt>:: may be a string (that will be parsed when calling the #body function), or an object (that will be returned as is when calling the #body function)
      def initialize(status, headers, body)
        @status = status.to_i
        @headers = sanitize_http_headers(headers)
        @body = body
      end
      
      def body
        if @body.kind_of?(String)
          if @body.empty?
            nil
          else
            @unserialized_body ||= unserialize(@body, :content_type => @headers['Content-Type'])
          end
        else
          @body
        end
      end
      
      def raw_body
        if @body.kind_of?(String)
          @body
        else
          @serialized_body ||= serialize(@body, :content_type => @headers['Content-Type']) unless @body.nil?
        end
      end
      
    end
  end
end