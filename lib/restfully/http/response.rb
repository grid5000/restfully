module Restfully
  module HTTP
    # Container for an HTTP Response. Has <tt>status</tt>, <tt>headers</tt> and <tt>body</tt> properties.
    # The body is automatically parsed into a ruby object based on the response's <tt>Content-Type</tt> header.
    class Response
      include Headers, Restfully::Parsing
      attr_reader :status, :headers, :body
      def initialize(status, headers, body)
        @status = status.to_i
        @headers = sanitize_http_headers(headers)
        @body = (body.nil? || body.empty?) ? nil : body.to_s
        @body = unserialize(@body, :content_type => @headers['Content-Type']) unless @body.nil?
      end
    end
  end
end