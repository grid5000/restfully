
module Restfully
  # Resource and Collection classes should clearly include a common module to deal with links, attributes, associations and loading
  class Collection < Resource
    include Enumerable
    attr_reader :items
    
    def initialize(uri, session, options = {})
      super(uri, session, options)
    end

    def reset
      super
      @items = Array.new
      @indexes = Hash.new
    end
    
    # find the first or all items whose uid is :uid (actually, there should always be only one item per uid...)
    # == Usage
    #   find("whatever", :all)
    # => [item1, item2]
    #   find("doesntexist", :all)
    # => []
    #   find("whatever")
    # => item1
    #   find("doesnotexist")
    # => nil
    def find(uid, scope=:first)
      @indexes[:by_uid] ||= @items.group_by{|i| i['uid']}
      found_items = (@indexes[:by_uid][uid.to_s] || [])
      if scope == :first
        found_items.first
      else
        found_items
      end
    end
    
    # if key is a Numeric, it returns the item at the corresponding index in the collection 
    # if key is a Symbol, it returns the item in the collection having uid == key.to_s
    # else, returns the value corresponding to that key in the attributes hash
    def [](key)
      if key.kind_of? Numeric
        @items[key]
      elsif key.kind_of? Symbol
        find(key, :first)
      else
        super(key)
      end
    end
    
    # iterate over the collection of items
    def each(*args, &block)
      @items.each(*args, &block)
    end

    def populate_object(key, value)
      case key
      when "links"
        value.each{|link| define_link(Link.new(link))}
      when "items"
        value.each do |item|
          self_link = (item['links'] || []).map{|link| Link.new(link)}.detect{|link| link.self?}
          if self_link && self_link.valid?
            @items.push Resource.new(self_link.href, session).load(:body => item)
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
    
    def length
      @items.length
    end
    
    def pretty_print(pp)
      super(pp) do |pp|
        if @items.length > 0
          pp.breakable
          pp.text "ITEMS (#{self["offset"]}..#{self["offset"]+@items.length})/#{self["total"]}"
          pp.nest 2 do
            @items.each_with_index do |item, i|
              pp.breakable
              pp.text "#<#{item.class}:0x#{item.object_id.to_s(16)} uid=#{item['uid'].inspect}>"            
              pp.text "," if i < @items.length-1
            end
          end
        end
      end
    end
    
    alias_method :size, :length
  end
end