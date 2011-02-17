module Restfully
  module HTTP
    
    class Request
      include Helper
      
      attr_reader :method, :uri, :head, :body
      
      def initialize(session, method, path, options)
        @session = session
        
        request = options.symbolize_keys
        request[:method] = method

        request[:head] = build_head(request)
        request[:body] = if [:post, :put].include?(request[:method])
          build_body(request)
        end

        request[:uri] = @session.uri_to(path)
        if request[:query]
          request[:uri].query = request[:query].to_params
        end
        request[:uri] = request[:uri].to_s

        @method, @uri, @head, @body = request.values_at(
          :method, :uri, :head, :body
        )
      end
      
      protected
      def build_head(options = {})
        sanitize_head(@session.default_headers).merge(
          sanitize_head(
            options.delete(:headers) || options.delete(:head) || {}
          )
        )
      end

      def build_body(options = {})
        if options[:body]
          type = MediaType.find(options[:head]['Content-Type'])
          if type.nil?
            type = MediaType.find('application/x-www-form-urlencoded')
            options[:head]['Content-Type'] = type.default_type
          end
          type.serialize(options[:body])
        else
          nil
        end
      end
      
    end
  end
end
