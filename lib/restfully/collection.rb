require 'delegate'

module Restfully
  class Collection < DelegateClass(Hash)
    
    attr_reader :state, :raw, :uri, :session, :title, :parent
    
    def initialize(uri, session, options = {})
      @uri = uri
      @title = options['title']
      @session = session
      @raw = options['raw']
      @state = :unloaded
      @items = {}
      @parent = options['parent']
      super(@items)
    end
    
    def <<(resource)
      @items.store(resource.guid, resource)
      self
    end
    
    # allows for short symbol access, instead of complete guid
    # ex:
    #   collection[:rennes] <=> collection["/sites/rennes"] if collection.uri == '/sites'
    # 
    def [](key)
      if key.is_a?(Symbol) && parent && title
        item = @items[File.join(parent.guid, title, key.to_s)]
      else
        item = @items[key]
      end
    end
    
    def loaded?;    @state == :loaded;    end
    
    def load(force_reload = false)
      if loaded? && force_reload == false
        self
      else
        @raw = session.get(uri) if raw.nil? || force_reload
        raw.each do |key, value|
          next if key == 'links'
          self_link = (value['links'] || []).map{|link| Link.new(link)}.detect{|link| link.self?}
          if self_link && self_link.valid?
            @items.store(key, Resource.new(self_link.href, session, 'raw' => value).load)
          else
            session.logger.warn "Resource #{key} does not have a 'self' link. skipped."
          end
        end       
        @state = :loaded
        self
      end
    end
    
  end
end