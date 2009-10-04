require 'delegate'

module Restfully
  
  # Suppose that the load method has been called on the resource before trying to access its attributes or associations
  
  class Resource < DelegateClass(Hash)
    
    undef :type if self.respond_to? :type
    attr_reader :uri, :session, :state, :raw, :uid, :associations, :type

    def initialize(uri, session, options = {})
      options = options.symbolize_keys
      @uri = uri
      @session = session
      @raw = options[:raw]
      @state = :unloaded
      @attributes = {}
      super(@attributes)
      @associations = {}
    end
    
    def loaded?;    @state == :loaded;    end
    
    def method_missing(method, *args)
      if association = @associations[method.to_s]
        session.logger.debug "Loading association #{method}, args=#{args.inspect}"
        association.load(*args)
      else
        super(method, *args)
      end
    end
  
    def load(options = {})
      options = options.symbolize_keys
      force_reload = !!options.delete(:reload) || options.has_key?(:query)
      if loaded? && !force_reload
        self
      else  
        @associations.clear
        @attributes.clear
        if raw.nil? || force_reload
          response = session.get(uri, options) 
          @raw = response.body
        end
        (raw['links'] || []).each{|link| define_link(Link.new(link))}
        raw.each do |key, value|
          case key
          when 'links'  then  next
          when 'uid'    then  @uid = value
          when 'type'   then  @type = value
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
    
    def inspect(options = {:space => "\t"})
      output = "#<#{self.class}:0x#{self.object_id.to_s(16)}"
      if loaded?
        output += "\n#{options[:space]}------------ META ------------"
        output += "\n#{options[:space]}@uri: #{uri.inspect}"
        output += "\n#{options[:space]}@uid: #{uid.inspect}"
        output += "\n#{options[:space]}@type: #{type.inspect}"
        @associations.each do |title, assoc|
          output += "\n#{options[:space]}@#{title}: #{assoc.class.name}"
        end
        unless @attributes.empty?
          output += "\n#{options[:space]}------------ PROPERTIES ------------"
          @attributes.each do |key, value|
            output += "\n#{options[:space]}#{key.inspect} => #{value.inspect}"
          end
        end
      end
      output += ">"
    end    
    
    protected
    def define_link(link)
      if link.valid?
        case link.rel
        when 'parent'
          @associations['parent'] = Resource.new(link.href, session)
        when 'collection'
          raw_included = link.resolved? ? raw[link.title] : nil
          @associations[link.title] = Collection.new(link.href, session, 
            :raw => raw_included,
            :title => link.title)
        when 'member'
          raw_included = link.resolved? ? raw[link.title] : nil
          @associations[link.title] = Resource.new(link.href, session, 
            :title => link.title,
            :raw => raw_included)
        when 'self'
          # we do nothing
        end
      else 
        session.logger.warn link.errors.join("\n")
      end
    end
    
  end # class Resource
end # module Restfully