require 'delegate'

module Restfully
  
  # Suppose that the load method has been called on the resource before trying to access its attributes or associations
  
  class Resource < DelegateClass(Hash)
    undef :type
    attr_reader :uri, :session, :state, :raw, :uid, :associations

    def initialize(uri, session, options = {})
      @uri = uri
      @session = session
      @parent = options['parent']
      @raw = options['raw']
      @state = :unloaded
      @attributes = {}
      super(@attributes)
      @associations = {}
    end
    
    def loaded?;    @state == :loaded;    end
    
    def method_missing(method, *args)
      if association = @associations[method.to_s]
        session.logger.debug "loading association #{method} with #{args.inspect}"
        association.load(*args)
      else
        super(method, *args)
      end
    end
  
    def load(options = {})
      options = options.symbolize_keys
      force_reload = options.delete(:reload) || false
      path = uri
      if options.has_key?(:query)
        path, query_string = uri.split("?")
        query_string ||= ""
        query_string.concat(options.delete(:query).to_params)
        path = "#{path}?#{query_string}"
        force_reload = true
      end
      if loaded? && force_reload == false
        self
      else
        @raw = session.get(path, options) if raw.nil? || force_reload
        @associations.clear
        @attributes.clear
        (raw['links'] || []).each{|link| define_link(Link.new(link))}
        raw.each do |key, value|
          case key
          when 'links'  then  next
          when 'uid'   then  @uid = value
          else
            case value
            when Hash
              @attributes.store(key, SpecialHash.new.replace(value)) unless @associations.has_key?(key)
            when Array
              @attributes.store(key, SpecialArray.new(value))
            else
              @attributes.store(key, value)
            end
          end
        end
        @state = :loaded
        self
      end
    end
    
    def respond_to?(method, *args)
      @associations.has_key?(method.to_s) || super(method, *args)
    end
    
    protected
    def define_link(link)
      if link.valid?
        case link.rel
        when 'collection'
          raw_included = link.resolved? ? raw[link.title] : nil
          @associations[link.title] = Collection.new(link.href, session, 
            'raw' => raw_included,
            'title' => link.title)
        when 'member'
          raw_included = link.resolved? ? raw[link.title] : nil
          @associations[link.title] = Resource.new(link.href, session, 
            'raw' => raw_included)
        when 'self'
          # uri is supposed to be equal to link['href'] for self relations. so we do nothing
        end
      else 
        session.logger.warn link.errors.join("\n")
      end
    end
    
  end # class Resource
end # module Restfully