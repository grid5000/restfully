
module Restfully
  # This includes the <tt>Enumerable</tt> module, but does not have all the
  # methods that you could expect from an <tt>Array</tt>.
  # Remember that this class inherits from a <tt>Restfully::Resource</tt> and
  # as such, the <tt>#[]</tt> method gives access to Resource properties, and
  # not to an item in the collection.
  # If you want to operate on the array of items, you MUST call <tt>#to_a</tt>
  # first (or <tt>#items</tt>) on the Restfully::Collection.
  class Collection < Resource
    include Enumerable
    attr_reader :items
    
    # See Resource#new
    def initialize(uri, session, options = {})
      super(uri, session, options)
    end

    # See Resource#reset
    def reset
      super
      @items = Array.new
      @indexes = Hash.new
      self
    end
    
    # Iterates over the collection of items
    def each(*args, &block)
      @items.each(*args, &block)
    end
    
    # if property is a Symbol, it tries to find the corresponding item whose uid.to_sym is matching the property
    # else, returns the result of calling <tt>[]</tt> on its superclass.
    def [](property)
      if property.kind_of?(Symbol)
        find{|i| i['uid'] == property.to_s} || find{|i| i['uid'] == property.to_s.to_i}
      else
        super(property)
      end
    end
    
    # Returns the current number of items (not the total number) 
    # in the collection.
    def length
      @items.length
    end

    def populate_object(key, value)
      case key
      when "links"
        value.each{|link| define_link(Link.new(link))}
      when "items"
        value.each do |item|
          self_link = (item['links'] || []).
            map{|link| Link.new(link)}.detect{|link| link.self?}
          if self_link && self_link.valid?
            @items.push Resource.new(uri_for(self_link.href), session).load(:body => item)
          else
            session.logger.warn "Resource #{key} does not have a 'self' link. skipped."
          end
        end
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

    def inspect
      @items.inspect
    end

    
    def pretty_print(pp)
      super(pp) do |inner_pp|
        if @items.length > 0
          inner_pp.breakable
          inner_pp.text "ITEMS (#{self["offset"]}..#{self["offset"]+@items.length})/#{self["total"]}"
          inner_pp.nest 2 do
            @items.each_with_index do |item, i|
              inner_pp.breakable
              inner_pp.text "#<#{item.class}:0x#{item.object_id.to_s(16)} uid=#{item['uid'].inspect}>"            
              inner_pp.text "," if i < @items.length-1
            end
          end
        end
      end
    end
    
    alias_method :size, :length
  end
end