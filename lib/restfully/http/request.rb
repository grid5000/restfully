

module Restfully
  module HTTP

    class Request
      include Helper

      attr_reader :session, :method, :uri, :head, :body, :attempts
      attr_accessor :retry_on_error, :wait_before_retry

      def initialize(session, method, path, options = {})
        @session = session
        @attempts = 0

        request = options.symbolize_keys

        @retry_on_error = request[:retry_on_error] || session.config[:retry_on_error]
        @wait_before_retry = request[:wait_before_retry] || session.config[:wait_before_retry]

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

      # Updates the request header and query parameters.
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

      def inspect
        "#{method.to_s.upcase} #{uri.to_s}, head=#{head.inspect}, body=#{body.inspect}"
      end

      def no_cache?
        head['Cache-Control'] && head['Cache-Control'].include?('no-cache')
      end

      def no_cache!
        @forced_cache = true
        head['Cache-Control'] = 'no-cache'
      end

      def forced_cache?
        !!@forced_cache
      end

      def execute!
        session.logger.debug self.inspect
        resource = RestClient::Resource.new(
          uri.to_s,
          :headers => head
        )

        begin
          reqcode, reqhead, reqbody = resource.send(method, body || {})
          response = Response.new(session, reqcode, reqhead, reqbody)
          session.logger.debug response.inspect
          response
        rescue Errno::ECONNREFUSED => e
          retry! || raise(e)
        end
      end

      def retry!
        if @attempts < @retry_on_error
          @attempts+=1
          session.logger.info "Encountered connection or server error. Retrying in #{@wait_before_retry}s... [#{@attempts}/#{@retry_on_error}]"
          sleep @wait_before_retry if @wait_before_retry > 0
          execute!
        else
          false
        end
      end

      def remove_no_cache!
        @forced_cache = false
        if head['Cache-Control']
          head['Cache-Control'] = head['Cache-Control'].split(/\s+,\s+/).reject{|v|
            v =~ /no-cache/i
          }.join(",")
        end
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
          type.serialize(options[:body], :serialization => options[:serialization])
        else
          nil
        end
      end

    end
  end
end
