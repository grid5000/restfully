require 'delegate'

module Restfully
  
  # Suppose that the load method has been called on the resource before trying to access its attributes or associations
  
  class Resource < DelegateClass(Hash)
    undef :type
    attr_writer :parent
    attr_reader :uri, :session, :state, :raw, :guid, :associations

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
    
    def parent     
      @parent.nil? ? nil : @parent.load
    end
    
    def method_missing(method, *args)
      if association = @associations[method.to_s]
        association.load
      else
        super(method, *args)
      end
    end
  
    def load(force_reload = false)
      if loaded? && force_reload == false
        self
      else
        @raw = session.get(uri) if raw.nil? || force_reload
        (raw['links'] || []).each{|link| define_link(Link.new(link))}
        raw.each do |key, value|
          case key
          when 'links'  then  next
          when 'guid'   then  @guid = value
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
            'parent' => self,
            'title' => link.title)
        when 'member'
          raw_included = link.resolved? ? raw[link.title] : nil
          @associations[link.title] = Resource.new(link.href, session, 'parent' => self, 'raw' => raw_included)
        when 'self'
          # uri is supposed to be equal to link['href'] for self relations. so we do nothing
        when 'parent'
          @parent = Resource.new(link.href, session)
        end
      else 
        session.logger.warn link.errors.join("\n")
      end
    end
    
  end # class Resource
end # module Restfully