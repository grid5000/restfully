require 'delegate'

module Restfully
  # Resource and Collection classes should clearly include a common module to deal with links, attributes, associations and loading
  class Collection < DelegateClass(Array)
    
    attr_reader :state, :raw, :uri, :session, :title, :offset, :total
    
    def initialize(uri, session, options = {})
      options = options.symbolize_keys
      @uri = uri
      @title = options[:title]
      @session = session
      @state = :unloaded
      @items = []
      @indexes = {}
      @associations = {}
      @attributes = {}
      super(@items)
    end
    
    def loaded?;    @state == :loaded;    end
    
    def method_missing(method, *args)
      load
      if association = @associations[method.to_s]
        session.logger.debug "Loading association #{method}, args=#{args.inspect}"
        association.load(*args)
      elsif method.to_s =~ /^by_(.+)$/
        key = $1
        @indexes[method.to_s] ||= @items.inject({}) { |accu, item| 
          accu[item.has_key?(key) ? item[key] : item.send(key.to_sym)] = item
          accu
        }
        if args.empty?
          @indexes[method.to_s]
        elsif args.length == 1
          @indexes[method.to_s][args.first]
        else
          @indexes[method.to_s].values_at(*args)
        end
      else
        super(method, *args)
      end
    end
    
    def load(options = {})
      options = options.symbolize_keys
      force_reload = !!options.delete(:reload) || options.has_key?(:query)
      if loaded? && !force_reload && options[:raw].nil?
        self
      else
        @raw = options[:raw]
        @associations.clear
        @attributes.clear
        @items.clear
        if raw.nil? || force_reload
          response = session.get(uri, options)
          @raw = response.body
        end
        raw.each do |key, value|
          case key
          when "total", "offset"
            instance_variable_set("@#{key}".to_sym, value)
          when "links"
            value.each{|link| define_link(Link.new(link))}
          when "items"
            value.each do |item|
              self_link = (item['links'] || []).map{|link| Link.new(link)}.detect{|link| link.self?}
              if self_link && self_link.valid?
                @items << Resource.new(self_link.href, session).load(:raw => item)
              else
                session.logger.warn "Resource #{key} does not have a 'self' link. skipped."
              end
            end
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
        output += "\n#{options[:space]}@offset: #{offset.inspect}"
        output += "\n#{options[:space]}@total: #{total.inspect}"
        @associations.each do |title, assoc|
          output += "\n#{options[:space]}@#{title}: #{assoc.class.name}"
        end
        unless @attributes.empty?
          output += "\n#{options[:space]}------------ PROPERTIES ------------"
          @attributes.each do |key, value|
            output += "\n#{options[:space]}#{key.inspect} => #{value.inspect}"
          end
        end
        unless @items.empty?        
          output += "\n#{options[:space]}------------ ITEMS ------------"
          @items.each do |value|
            output += "\n#{options[:space]}#{value.class.name}"
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
  end
end