require 'logger'
require 'uri'
require 'open-uri'

require 'restclient'
require 'restclient/components'
require 'rack/cache'
require 'addressable/uri'

require 'restfully/sandbox'

module Restfully
  class Session

    attr_accessor :uri
    attr_reader :config
    attr_writer :default_headers
    
    def logger
      @config.logger
    end

    # Builds a new client session.
    # Takes a number of <tt>options</tt> as input.
    # Yields or return the <tt>root</tt> Restfully::Resource object, and the Restfully::Session object.
    #
    # <tt>:configuration_file</tt>:: the location of a YAML configuration file that contains any of the parameters below.
    # <tt>:uri</tt>:: the entry-point URI for this session.
    # <tt>:logger</tt>:: a Logger object, used to display information.
    # <tt>:require</tt>:: an Array of Restfully::MediaType objects to automatically require for this session.
    # <tt>:retry_on_error</tt>:: the maximum number of attempts to make when a server (502,502,504) or connection error occurs.
    # <tt>:wait_before_retry</tt>:: the number of seconds to wait before making another attempt when a server or connection error occurs.
    # <tt>:default_headers</tt>:: a Hash of default HTTP headers to send with each request.
    # <tt>:cache</tt>:: a Hash of parameters to configure the caching component. See <http://rtomayko.github.com/rack-cache/configuration> for more information.
    #
    # e.g.
    #   Restfully::Session.new(
    #     :uri => "https://api.bonfire-project.eu:444/",
    #     :username => "crohr",
    #     :password => "PASSWORD",
    #     :require => ['ApplicationVndBonfireXml']
    #   ) {|root, session| p root}
    #
    def initialize(options = {})
      @config = if options.kind_of?(Configuration)
        options
      else
        Configuration.new(options).expand
      end

      setup

      yield root, self if block_given?
    end
    
    def setup
      # Compatibility with :base_uri parameter of Restfully <= 0.6
      @uri = config[:uri] || config[:base_uri]
      msg = if @uri.nil? || @uri.empty?
        @uri = Restfully::DEFAULT_URI
        "No URI given. Using #{@uri}"
      else
        "Base URI changed to: #{@uri}" 
      end
      if config[:overridden] || @uri == Restfully::DEFAULT_URI
        config[:shell] ? puts(msg) : logger.warn(msg)
      end

      @uri = Addressable::URI.parse(@uri)

      default_headers.merge!(config[:default_headers] || {})

      disable RestClient::Rack::Compatibility
      authenticate(config)
      setup_cache(config[:cache])

      # Require additional types (e.g.: media-types):
      (config[:require] || []).each do |r|
        logger.info "Requiring #{r}..."
        if ::File.exist?(file=File.expand_path(r))
          require file
        elsif r =~ /^https?:\/\//i
          begin
            resource = get(r)
            file = Tempfile.new(['restfully', '.rb'])
            file << resource.response.body
            file.close
            require file.path.gsub(/\.rb^/,'')
          rescue HTTP::Error => e
            logger.fatal "Can't fetch #{r} from the Internet. Aborting."
            raise e
          end
        else
          require "restfully/media_type/#{r.underscore}"
        end
      end
    end

    # Enable a RestClient Rack component.
    def enable(rack, *args)
      logger.info "Enabling #{rack.inspect}."
      RestClient.enable rack, *args
    end

    # Disable a RestClient Rack component.
    def disable(rack, *args)
      logger.info "Disabling #{rack.inspect}."
      RestClient.disable rack, *args
    end

    # Returns the list of middleware components enabled.
    # See rest-client-components for more information.
    def middleware
      RestClient.components.map{|(rack, args)| rack}
    end

    # Authnenticates the request using Basic Authentication.
    def authenticate(options = {})
      if options[:username]
        enable(
          Restfully::Rack::BasicAuth,
          options[:username],
          options[:password]
        )
      end
    end

    # Builds the complete URI, based on the given path and the session's uri
    def uri_to(path)
      Addressable::URI.join(uri.to_s, path.to_s)
    end

    # Return the Hash of default HTTP headers that are sent with each request.
    def default_headers
      @default_headers ||= {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip, deflate',
        'User-agent' => "Restfully/#{Restfully::VERSION}" 
      }
    end

    # Returns the root Restfully::Resource.
    def root
      get(uri.path).load
    end
    
    # Return a sandbox object, useful to execute code within the current
    # session context witout polluting the Session object.
    def sandbox
      Sandbox.new(self)
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def head(path, options = {})
      transmit :head, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def get(path, options = {})
      transmit :get, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def post(path, body, options = {})
      options[:body] = body
      transmit :post, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def put(path, body, options = {})
      options[:body] = body
      transmit :put, path, options
    end

    # Returns an HTTP::Response object or raise a Restfully::HTTP::Error
    def delete(path, options = {})
      transmit :delete, path, options
    end

    # Process a Restfully::HTTP::Response.
    def process(response, request)
      case code=response.code
      when 200
        logger.debug "Building response..."
        Resource.new(self, response, request).build
      when 201,202
        logger.debug "Following redirection to: #{response.head['Location'].inspect}"
        get response.head['Location'], :head => request.head
      when 204
        true
      when 400..499
        raise HTTP::ClientError, error_message(request, response)
      when 502..504
        if res = request.retry!
          process(res, request)
        else
         raise(HTTP::ServerError, error_message(request, response))
       end
      when 500, 501
        raise HTTP::ServerError, error_message(request, response)
      else
        raise Error, "Restfully does not handle code #{code.inspect}."
      end
    end

    protected
    # Build and execute the corresponding HTTP request,
    # then process the response.
    def transmit(method, path, options)
      request = HTTP::Request.new(self, method, path, options)
      response = request.execute!
      process(response, request)
    end

    def setup_cache(options = {})
      return if options == false
      opts = {:verbose => (logger.level <= Logger::INFO)}.merge(
        (options || {}).symbolize_keys
      )
      enable ::Rack::Cache, opts
    end

    def error_message(request, response)
      msg = "Encountered error #{response.code} on #{request.method.upcase} #{request.uri}"
      msg += " --- #{response.body}" unless response.body.empty?
    end

  end

end
