module Restfully
  # This class represents a Resource, which can be accessed and manipulated
  # via HTTP methods.
  #
  # The <tt>#load</tt> method must have been called on the resource before
  # trying to access its attributes or links.
  #
  class Resource
    attr_reader :response, :request, :session

    HIDDEN_PROPERTIES_REGEXP = /^\_\_(.+)\_\_$/

    def initialize(session, response, request)
      @session = session
      @response = response
      @request = request
      @associations = {}
    end

    # == Description
    # Returns the value corresponding to the specified key,
    # among the list of resource properties
    #
    # == Usage
    #   resource["uid"]
    #   => "rennes"
    def [](key)
      reload_if_empty(self)
      media_type.property(key)
    end

    def uri
      request.uri
    end

    def media_type
      response.media_type
    end
    
    def complete?
      media_type.complete?
    end

    def collection?
      media_type.collection?
    end
    
    def kind
      collection? ? "Collection" : "Resource"
    end
    
    def signature(closed=true)
      s = "#<#{kind}:0x#{object_id.to_s(16)}"
      s += " uri=#{uri.to_s}"
      s += ">" if closed
      s
    end

    def load(options = {})
      # Send a GET request only if given a different set of options
      if @request.update!(options) || @request.no_cache?
        @response = session.execute(@request)
        @request.remove_no_cache! if @request.forced_cache?
        if session.process(@response, @request)
          @associations.clear
        else
          raise Error, "Cannot reload the resource"
        end
      end
      
      build
    end
    
    def relationships
      response.links.map(&:id).sort
    end
    
    def properties
      media_type.property.reject{|k,v|        
        # do not return keys used for internal use
        k.to_s =~ HIDDEN_PROPERTIES_REGEXP
      }
    end
    
    # For the following methods, maybe it's better to always go through the
    # cache instead of explicitly saying @request.no_cache! (and update the
    # #load method accordingly)
    
    # Force reloading of the request
    def reload
      @request.no_cache!
      load
    end

    def submit(*args)
      if allow?(:post)
        @request.no_cache!
        payload, options = extract_payload_from_args(args)
        session.post(request.uri, payload, options)
      else
        raise MethodNotAllowed
      end
    end

    def delete(options = {})
      if allow?(:delete)
        @request.no_cache!
        session.delete(request.uri)
      else
        raise MethodNotAllowed
      end
    end

    def update(*args)
      if allow?(:put)
        @request.no_cache!
        payload, options = extract_payload_from_args(args)
        session.put(request.uri, payload, options)
      else
        raise MethodNotAllowed
      end
    end

    def allow?(method)
      response.allow?(method)
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

    

    def build
      metaclass = class << self; self; end
      # only build once
      # if @associations.empty?
        extend Collection if collection?

        response.links.each do |link|
          metaclass.send(:define_method, link.id.to_sym) do |*args|
            session.get(link.href, :head => {
              'Accept' => link.type
            }).load(*args)
          end
          
        end
      # end
      self
    end
    
    def expand
      reload_if_empty(self)
    end

    protected
    def extract_payload_from_args(args)
      options = args.extract_options!
      head = options.delete(:headers) || options.delete(:head)
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
    
    def reload_if_empty(resource)
      resource.reload if resource && !resource.complete?
      resource
    end
  end
end
