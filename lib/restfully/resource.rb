module Restfully
  # This class represents a Resource, which can be accessed and manipulated
  # via HTTP methods.
  #
  # Some resources can be collection of other resources.
  # In that case the <tt>Restfully::Collection</tt> module is included in the <tt>Restfully::Resource</tt> class.
  # See the corresponding documentation for the list of additional methods that you can use on a collection resource.
  class Resource
    attr_reader :response, :request, :session

    HIDDEN_PROPERTIES_REGEXP = /^\_\_(.+)\_\_$/

    def initialize(session, response, request)
      @session = session
      @response = response
      @request = request
      @associations = {}
    end

    # Returns the value corresponding to the specified key,
    # among the list of resource properties.
    #
    # e.g.:
    #   resource["uid"]
    #   => "rennes"
    def [](key)
      if !media_type.property(key) && !collection?
        expand
      end
      media_type.property(key)
    end

    # Returns the resource URI.
    def uri
      request.uri
    end

    # Returns the Restfully::MediaType object that was used to parse the response.
    def media_type
      response.media_type
    end

    # Does this resource contain only a fragment of the full resource?
    def complete?
      media_type.complete?
    end

    # Is this resource a collection of items?
    def collection?
      media_type.collection?
    end

    # Returns the resource kind: "Collection" or "Resource".
    def kind
      collection? ? "Collection" : "Resource"
    end

    # Returns the "signature" of the resource. Used for (pretty-)inspection.
    def signature(closed=true)
      s = "#<#{kind}:0x#{object_id.to_s(16)}"
      s += media_type.banner unless media_type.banner.nil?
      # Only display path if host and port are the same than session's URI:
      s += " uri=#{[uri.host, uri.port] == [
        session.uri.host, session.uri.port
      ] ? uri.request_uri.inspect : uri.to_s.inspect}"
      s += ">" if closed
      s
    end

    # Load the resource. The <tt>options</tt> Hash can contain any number of parameters among which:
    # <tt>:head</tt>:: a Hash of HTTP headers to pass when fetching the resource.
    # <tt>:query</tt>:: a Hash of query parameters to add to the URI when fetching the resource.
    def load(options = {})
      # Send a GET request only if given a different set of options
      if @request.update!(options) || @request.no_cache?
        @response = @request.execute!
        @request.remove_no_cache! if @request.forced_cache?
        if session.process(@response, @request)
          @associations.clear
        else
          raise Error, "Cannot reload the resource"
        end
      end

      build
    end

    # Returns the list of relationships for this resource, extracted from the resource links ("rel" attribute).
    def relationships
      response.links.map(&:id).sort
    end

    # Returns the properties for this resource.
    def properties
      case props = media_type.property
      when Hash
        props.reject{|k,v|
          # do not return keys used for internal use
          k.to_s =~ HIDDEN_PROPERTIES_REGEXP
        }
      else
        props
      end
    end

    # Force reloading of the resource.
    def reload
      @request.no_cache!
      load
    end

    # POST some payload on that resource URI.
    # Either you pass a serialized payload as first argument, followed by an optional Hash of <tt>:head</tt> and <tt>:query</tt> parameters.
    # Or you pass your payload as a Hash, and the serialization will occur based on the Content-Type you set (and only if a corresponding MediaType can be found in the MediaType catalog).
    def submit(*args)
      if allow?("POST")
        @request.no_cache!
        payload, options = extract_payload_from_args(args)
        session.post(request.uri, payload, options)
      else
        raise MethodNotAllowed
      end
    end

    # Send a DELETE HTTP request on the resource URI.
    # See <tt>#load</tt> for the list of arguments this method can take.
    def delete(options = {})
      if allow?("DELETE")
        @request.no_cache!
        session.delete(request.uri)
      else
        raise MethodNotAllowed
      end
    end

    # Send a PUT HTTP request with some payload on the resource URI.
    # See <tt>#submit</tt> for the list of arguments this method can take.
    def update(*args)
      if allow?("PUT")
        @request.no_cache!
        payload, options = extract_payload_from_args(args)
        session.put(request.uri, payload, options)
      else
        raise MethodNotAllowed
      end
    end

    # Returns true if the resource supports the given HTTP <tt>method</tt> (String or Symbol).
    def allow?(method)
      response.allow?(method) || reload.response.allow?(method)
    end

    def inspect
      if media_type.complete?
        properties.inspect
      else
        "{...}"
      end
    end

    def pretty_print(pp)
      pp.text signature(false)
      pp.nest 2 do
        if relationships.length > 0
          pp.breakable
          pp.text "RELATIONSHIPS"
          pp.nest 2 do
            pp.breakable
            pp.text "#{relationships.join(", ")}"
          end
        end
        pp.breakable
        if collection?
          # display items
          pp.text "ITEMS (#{offset}..#{offset+length})/#{total}"
          pp.nest 2 do
            self.each do |item|
              pp.breakable
              pp.text item.signature(true)
            end
          end
        else
          expand
          pp.text "PROPERTIES"
          pp.nest 2 do
            properties.each do |key, value|
              pp.breakable
              pp.text "#{key.inspect}=>"
              value.pretty_print(pp)
            end
          end
        end
        yield pp if block_given?
      end
      pp.text ">"
      nil
    end

    # Build the resource after loading.
    def build
      extend Collection if collection?
      metaclass = class << self; self; end
      response.links.each do |link|
        metaclass.send(:define_method, link.id.to_sym) do |*args|
          session.get(link.href, :head => {
            'Accept' => link.type
          }).load(*args)
        end
      end
      self
    end

    # Reload itself if the resource is not <tt>#complete?</tt>.
    def expand
      reload unless complete?
      self
    end

    protected
    def extract_payload_from_args(args)
      options = args.extract_options!
      head = options.delete(:headers) || options.delete(:head) || {}
      head['Origin-Content-Type'] = response.head['Content-Type']

      query = options.delete(:query)

      payload = args.shift || options

      options = {
        :head => head, :query => query,
        :serialization => media_type.property.reject{|k,v|
          k !~ HIDDEN_PROPERTIES_REGEXP
        }
      }

      [payload, options]
    end

  end
end
