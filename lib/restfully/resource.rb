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


    def load
      # only load once
      if @associations.empty?
        extend Collection if media_type.collection?

        response.links.each do |link|
          @associations[link.id] = nil
          
          self.class.class_eval do
            define_method link.id do
              @associations[link.id] ||= session.get(link.href, :head => {
                'Accept' => link.type
              }).load
            end
          end
          
        end
      end
      
      self
    end
    
    def relationships
      @associations.keys
    end
    
    def reload
      @request.head['Cache-Control'] = 'no-cache'
      @response = session.execute(request)
      if session.process(response, request)
        @associations.clear
        load
      else
        raise Error, "Cannot reload the resource"
      end
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
      if response.allow?(:delete)
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
      "#<#{self.class}:0x#{self.object_id.to_s(16)}" +
      " : #{media_type.meta.inspect}" +
      ">"
    end
    
    def pretty_print(pp)
      pp.text "#<#{self.class}:0x#{self.object_id.to_s(16)}"
      # pp.text " uid=#{self['uid'].inspect}" if self.class == Resource
      pp.nest 2 do
        pp.breakable
        pp.text "@uri="
        uri.pretty_print(pp)
        if relationships.length > 0
          pp.breakable
          pp.text "RELATIONSHIPS"
          pp.nest 2 do
            relationships.each_with_index do |rel, i|
              pp.breakable
              pp.text "@#{rel}=#<#{Resource.name}>"
              pp.text "," if i < relationships.length-1
            end
          end
        end
        if media_type.collection?
          # display items
        else
          pp.breakable
          pp.text "PROPERTIES"
          pp.nest 2 do
            media_type.meta.to_a.each_with_index do |(key, value), i|
              pp.breakable
              pp.text "#{key.inspect}=>"
              value.pretty_print(pp)
              pp.text "," if i < media_type.meta.length-1
            end
          end
        end
        yield pp if block_given?
      end
      pp.text ">"
    end

    protected
    def extract_payload_from_args(args)
      options = args.extract_options!
      head = options.delete(:headers)
      query = options.delete(:query)

      payload = args.shift || options
      
      options = {
        :head => head, :query => query
      }
      
      [payload, options]
    end
  end
end
