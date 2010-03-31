module Restfully
  
  # This class represents a Resource, which can be accessed and manipulated
  # via HTTP methods.
  # 
  # The <tt>#load</tt> method must have been called on the resource before
  # trying to access its attributes or links.
  # 
  class Resource
    
    attr_reader :uri, 
                :session, 
                :links, 
                :title, 
                :properties, 
                :executed_requests
    
    # == Description
    # Creates a new Resource.
    # <tt>uri</tt>:: a URI object representing the URI of the resource
    #                (complete, absolute or relative URI)
    # <tt>session</tt>:: an instantiated Restfully::Session object
    # <tt>options</tt>:: a hash of options (see below)
    # == Options
    # <tt>:title</tt>:: an optional title for the resource
    def initialize(uri, session, options = {})
      options = options.symbolize_keys
      @uri = uri.kind_of?(URI) ? uri : URI.parse(uri.to_s)
      @session = session
      @title = options[:title]
      reset
    end
    
    # Resets all the inner objects of the resource
    # (you must call <tt>#load</tt> if you want to repopulate the resource).
    def reset
      @executed_requests = Hash.new
      @links = Hash.new
      @properties = Hash.new
      @status = :stale
      self
    end
    
    # == Description
    # Returns the value corresponding to the specified key, 
    # among the list of resource properties
    # 
    # == Usage
    #   resource["uid"]
    #   => "rennes"
    def [](key)
      @properties[key]
    end
    
    def respond_to?(method, *args)
      @links.has_key?(method.to_s) || super(method, *args)
    end
    
    def method_missing(method, *args)
      if link = @links[method.to_s]
        session.logger.debug "Loading link #{method}, args=#{args.inspect}"
        link.load(*args)
      else
        super(method, *args)
      end
    end
    
    # == Description
    # Executes a GET request on the resource, and populate the list of its
    # properties and links
    # <tt>options</tt>:: list of options to pass to the request (see below)
    # == Options
    # <tt>:reload</tt>:: if set to true, a GET request will be triggered 
    #                    even if the resource has already been loaded [default=false]
    # <tt>:query</tt>:: a hash of query parameters to pass along the request. 
    #                   E.g. : resource.load(:query => {:from => (Time.now-3600).to_i, :to => Time.now.to_i})
    # <tt>:headers</tt>:: a hash of HTTP headers to pass along the request. 
    #                     E.g. : resource.load(:headers => {'Accept' => 'application/json'})
    # <tt>:body</tt>:: if you already have the unserialized response body of this resource, 
    #                  you may pass it so that the GET request is not triggered.
    def load(options = {})
      options = options.symbolize_keys
      force_reload = !!options.delete(:reload)
      stale! unless !force_reload && (request = executed_requests['GET']) && request['options'] == options && request['body']
      if stale?
        reset
        if !force_reload && options[:body]
          body = options[:body]
          headers = {}
        else
          response = session.get(uri, options)
          body = response.body
          headers = response.headers
        end
        executed_requests['GET'] = {
          'options' => options, 
          'body' =>  body,
          'headers' => headers
        }
        executed_requests['GET']['body'].each do |key, value|
          populate_object(key, value)
        end
        @status = :loaded
      end
      self
    end
    
    # Convenience function to make a resource.load(:reload => true)
    def reload
      current_options = executed_requests['GET']['options'] rescue {}
      stale!
      self.load(current_options.merge(:reload => true))
    end
  
    # == Description
    # Executes a POST request on the resource, reload it and returns self if successful.
    # If the response status is different from 2xx, raises a HTTP::ClientError or HTTP::ServerError.
    # <tt>payload</tt>:: the input body of the request.
    #                    It may be a serialized string, or a ruby object 
    #                    (that will be serialized according to the given or default content-type).
    # <tt>options</tt>:: list of options to pass to the request (see below)
    # == Options
    # <tt>:query</tt>:: a hash of query parameters to pass along the request. 
    #                   E.g. : resource.submit("body", :query => {:param1 => "value1"})
    # <tt>:headers</tt>:: a hash of HTTP headers to pass along the request. 
    #                     E.g. : resource.submit("body", :headers => {:accept => 'application/json', :content_type => 'application/json'})
    def submit(payload, options = {})
      options = options.symbolize_keys
      raise NotImplementedError, "The POST method is not allowed for this resource." unless http_methods.include?('POST')
      raise ArgumentError, "You must pass a payload" if payload.nil?
      headers = {
        :content_type => (executed_requests['GET']['headers']['Content-Type'] || "application/x-www-form-urlencoded").split(/,/).sort{|a,b| a.length <=> b.length}[0],
        :accept => (executed_requests['GET']['headers']['Content-Type'] || "text/plain")
      }.merge(options[:headers] || {})
      options = {:headers => headers}
      options.merge!(:query => options[:query]) unless options[:query].nil?
      response = session.post(self.uri, payload, options) # raises an exception if there is an error
      stale!
      if [201, 202].include?(response.status)
        Resource.new(uri_for(response.headers['Location']), session).load
      else
        reload
      end
    end
    
    # == Description
    # Executes a DELETE request on the resource, and returns true if successful.
    # If the response status is different from 2xx or 3xx, raises an HTTP::ClientError or HTTP::ServerError.
    # <tt>options</tt>:: list of options to pass to the request (see below)
    # == Options
    # <tt>:query</tt>:: a hash of query parameters to pass along the request. 
    #                   E.g. : resource.delete(:query => {:param1 => "value1"})
    # <tt>:headers</tt>:: a hash of HTTP headers to pass along the request. 
    #                     E.g. : resource.delete(:headers => {:accept => 'application/json'})
    def delete(options = {})
      options = options.symbolize_keys
      raise NotImplementedError, "The DELETE method is not allowed for this resource." unless http_methods.include?('DELETE')
      response = session.delete(self.uri, options) # raises an exception if there is an error
      stale!
      (200..399).include?(response.status)
    end
    
    
    def stale!; @status = :stale;  end
    def stale?; @status == :stale; end

    
    # == Description
    # Returns the list of allowed HTTP methods on the resource.
    # == Usage
    #   resource.http_methods    
    #   => ['GET', 'POST']
    # 
    def http_methods
      reload if executed_requests['GET'].nil? || executed_requests['GET']['headers'].nil? || executed_requests['GET']['headers'].empty?
      (executed_requests['GET']['headers']['Allow'] || "GET").split(/,\s*/)
    end
    
    def uri_for(path)
      uri.merge(URI.parse(path.to_s))
    end
    
    def inspect(*args)
      @properties.inspect(*args)
    end
    
    def pretty_print(pp)
      pp.text "#<#{self.class}:0x#{self.object_id.to_s(16)}"
      pp.text " uid=#{self['uid'].inspect}" if self.class == Resource
      pp.nest 2 do
        pp.breakable
        pp.text "@uri="
        uri.pretty_print(pp)
        if @links.length > 0
          pp.breakable
          pp.text "LINKS"
          pp.nest 2 do
            @links.to_a.each_with_index do |(key, value), i|
              pp.breakable
              pp.text "@#{key}=#<#{value.class}:0x#{value.object_id.to_s(16)}>"
              pp.text "," if i < @links.length-1
            end
          end  
        end
        if @properties.length > 0
          pp.breakable
          pp.text "PROPERTIES"
          pp.nest 2 do
            @properties.to_a.each_with_index do |(key, value), i|
              pp.breakable
              pp.text "#{key.inspect}=>"
              value.pretty_print(pp)
              pp.text "," if i < @properties.length-1
            end
          end
        end
        yield pp if block_given?
      end
      pp.text ">"
    end   
    
    protected
    def populate_object(key, value)
      case key
      when "links"
        value.each{|link| define_link(Link.new(link))}
      else
        case value
        when Hash
          @properties.store(key, SpecialHash.new.replace(value)) unless @links.has_key?(key)
        when Array
          @properties.store(key, SpecialArray.new(value))
        else
          @properties.store(key, value)
        end
      end
    end
    def define_link(link)
      if link.valid?
        case link.rel
        when 'parent'
          @links['parent'] = Resource.new(uri.merge(link.href), session)
        when 'collection'
          @links[link.title] = Collection.new(uri.merge(link.href), session, :title => link.title)
        when 'member'
          @links[link.title] = Resource.new(uri.merge(link.href), session, :title => link.title)
        when 'self'
          # we do nothing
        end
      else 
        session.logger.warn link.errors.join("\n")
      end
    end
    
  end # class Resource
end # module Restfully