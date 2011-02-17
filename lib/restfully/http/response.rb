module Restfully
  module HTTP
    class Response
      include Helper
      
      attr_reader :io, :code, :head
      
      def initialize(session, code, head, body)
        @session = session
        @io = StringIO.new
        case body
        when String
          @io << body
        else
          body.each{|chunk| @io << chunk}
        end
        @io.rewind
        
        @code = code
        @head = sanitize_head(head)
      end
      
      def body
        @io.rewind
        @body = @io.read
        @io.rewind
        @body
      end
      
      def io
        @io
      end
      
      def media_type
        @media_type ||= begin
          m = MediaType.find(head['Content-Type'])
          raise Error, "Cannot find a media-type for content-type=#{head['Content-Type'].inspect}" if m.nil?
          m.new(io)
        end
      end
      
      # TODO: we could also search for Link headers here.
      def links
        media_type.links
      end
      
      def property(key)
        media_type.property(key)
      end
      
      def allow?(http_method)
        http_method = http_method.to_sym
        return true if http_method == :get
        (
          media_type.respond_to?(:allow?) && 
          media_type.allow?(http_method)
        ) || (
          head['Allow'] &&
          head['Allow'].split(/\s*,\s*/).map{|m| 
            m.downcase.to_sym
          }.include?(http_method)
        )          
      end
      
    end
  end
end
