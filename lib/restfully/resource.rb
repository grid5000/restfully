module Restfully
  # This class represents a Resource, which can be accessed and manipulated
  # via HTTP methods.
  #
  # The <tt>#load</tt> method must have been called on the resource before
  # trying to access its attributes or links.
  #
  class Resource
    attr_reader :response, :request, :session

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
      media_type.property(key)
    end

    def uri
      request.uri
    end

    def media_type
      response.media_type
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
        if session.process(@response, @request)
          @associations.clear
        else
          raise Error, "Cannot reload the resource"
        end
      end
      
      build
    end
    
    def relationships
      @associations.keys
    end
    
    def properties
      media_type.property.reject{|k,v|        
        # do not return keys used for internal use
        k.to_s =~ /^\_\_(.+)\_\_$/
      }
    end
    
    def reload
      load(:head => {'Cache-Control' => 'no-cache'})      
    end

    def submit(*args)
      if allow?(:post)
        payload, options = extract_payload_from_args(args)
        session.post(request.uri, payload, options)
      else
        raise MethodNotAllowed
      end
    end

    def delete(options = {})
      if allow?(:delete)
        session.delete(request.uri)
      else
        raise MethodNotAllowed
      end
    end

    def update(*args)
      if allow?(:put)
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
    end

    def build
      # only build once
      if @associations.empty?
        extend Collection if collection?

        response.links.each do |link|
          @associations[link.id] = nil
          
          self.class.class_eval do
            define_method link.id do |*args|
              @associations[link.id] ||= session.get(link.href, :head => {
                'Accept' => link.type
              }).load(*args)
            end
          end
          
        end
      end
      self
    end

    protected
    def extract_payload_from_args(args)
      options = args.extract_options!
      head = options.delete(:headers) || options.delete(:head)
      query = options.delete(:query)

      payload = args.shift || options
      
      options = {
        :head => head, :query => query
      }
      
      [payload, options]
    end
    

  end
end
