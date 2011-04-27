

module Restfully
  module HTTP
    
    class Request
      include Helper
      
      attr_reader :method, :uri, :head, :body
      
      def initialize(session, method, path, options)
        @session = session
        
        request = options.symbolize_keys
        request[:method] = method

        request[:head] = sanitize_head(@session.default_headers).merge(
          build_head(request)
        )
        
        request[:uri] = @session.uri_to(path)
        if request[:query]
          request[:uri].query_values = sanitize_query(request[:query])
        end
        
        request[:body] = if [:post, :put].include?(request[:method])
          build_body(request)
        end

        @method, @uri, @head, @body = request.values_at(
          :method, :uri, :head, :body
        )
      end
      
      # Updates the request header and query parameters
      # Returns nil if no changes were made, otherwise self.
      def update!(options = {})
        objects_that_may_be_updated = [@uri, @head]
        old_hash = objects_that_may_be_updated.map(&:hash)
        opts = options.symbolize_keys
        @head.merge!(build_head(opts))
        if opts[:query]
          @uri.query_values = sanitize_query(opts[:query])
        end
        if old_hash == objects_that_may_be_updated.map(&:hash)
          nil
        else
          self
        end
      end
      
      def no_cache?
        head['Cache-Control'] && head['Cache-Control'].include?('no-cache')
      end
      
      protected
      def build_head(options = {})
        sanitize_head(
          options.delete(:headers) || options.delete(:head) || {}
        )
      end

      def build_body(options = {})
        if options[:body]
          type = MediaType.find(options[:head]['Content-Type'])
          if type.nil?
            type = MediaType.find('application/x-www-form-urlencoded')
            options[:head]['Content-Type'] = type.default_type
          end
          type.serialize(options[:body], :uri => options[:uri])
        else
          nil
        end
      end
      
    end
  end
end
