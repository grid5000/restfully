module Restfully
  module Collection
    include Enumerable
    
    # If property is a Symbol, it tries to find the corresponding item in the collection.
    # Else, returns the result of calling <tt>[]</tt> on its superclass.
    def [](property)
      if property.kind_of?(Symbol)
        find{ |i| i.media_type.represents?(property) }
      else
        super(property)
      end
    end
    
    def each(*args, &block)
      media_type.each(*args) do |item_media_type|
        self_link = item_media_type.links.find{|l| l.self?}
        
        req = HTTP::Request.new(session, :get, self_link.href, :head => {
          'Accept' => self_link.types[0]
        })
        
        res = HTTP::Response.new(session, 200, {
          'Content-Type' => self_link.types[0]
        }, item_media_type.io)
        
        block.call Resource.new(session, res, req).load
      end
    end
    
    def total
      self["total"].to_i
    end
    
    def offset
      (self["offset"] || 0).to_i
    end
    
  end
  
end