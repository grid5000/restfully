module Restfully
  module Collection
    include Enumerable

    # If property is a Symbol, it tries to find the corresponding item in the collection.
    # Else, returns the result of calling <tt>[]</tt> on its superclass.
    def [](property)
      case property
      when Symbol
        find_by_uid(property)
      when Integer
        find_by_index(property)
      else
        super(property)
      end
    end

    def find_by_uid(symbol)
      found = find{ |i| i.media_type.represents?(symbol) }
      if found.nil? && !@seen_all_collection && session.config[:guess_paged_items]
        begin
          tentative_path = last.uri.to_s.gsub(last["uid"].to_s,symbol.to_s)
          found = session.get(tentative_path).load
        rescue
          found = nil
        end
      end
      found.expand unless found.nil?
      found
    end

    def find_by_index(index)
      index = index+length if index < 0
      each_with_index{|item, i|
        return item.expand if i == index
      }
      nil
    end

    def each(*args, &block)
      @items ||= {}
      items_visited=0
      @seen_all_collection=true
      media_type.each(*args) do |item_media_type|
        items_visited+=1
        hash = item_media_type.hash
        unless @items.has_key?(hash)
          self_link = item_media_type.links.find{|l| l.self?}

          req = HTTP::Request.new(session, :get, self_link.href, :head => {
            'Accept' => self_link.types[0]
          })

          res = HTTP::Response.new(session, 200, {
            'Content-Type' => self_link.types[0]
          }, item_media_type.io)

          @items[hash] = Resource.new(session, res, req).load
        end
        block.call @items[hash]
      end
      if items_visited < total
        # might need to get the next page of items
        # for that collection and iterate through it
        # to find what we are looking for
        @seen_all_collection=false
      end
      self
    end

    def length
      self["items"].length
    end

    def total
      self["total"].to_i
    end

    def offset
      (self["offset"] || 0).to_i
    end

    def last
      self[-1]
    end

    def empty?
      total == 0
    end

    # Expand the items that
    def expand
      each {|i| i.expand}
      self
    end

    def inspect
      map{|item| item}.inspect
    end
  end

end
