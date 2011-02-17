require 'set'

module Restfully
  module MediaType

    class AbstractMediaType

      class << self
        
        def parent(method)
          if superclass.respond_to?(method)
            superclass.send(method)
          else
            nil
          end
        end

        # @return [Hash] the hash of default options set.
        def defaults
          @defaults ||= (parent(:defaults) || {}).dup
        end

        # Sets a new <tt>value</tt> for a default <tt>attribute</tt>.
        def set(attribute, value)
          defaults[attribute.to_sym] = value
        end
        
        def signature
          [(defaults[:signature] || [])].flatten
        end
        
        def parser
          defaults[:parser]
        end
        
        def default_type
          signature.first
        end
        
        def supports?(*types)
          types.each do |type|
            type = type.to_s.downcase.split(";")[0]
            found = signature.find{ |s|
              type =~ Regexp.new(Regexp.escape(s.downcase).gsub('\*', ".*"))
            }
            return found if found
          end
          nil
        end
        
        
        def serialize(object, *args)
          case object
          when String
            object
          else
            parser.dump(object, *args)
          end
        end

        def unserialize(io, *args)
          parser.load(io, *args)
        end
        
      end
      
      attr_reader :io

      def initialize(io)
        @io = io
      end

      # Do not overwrite directly. Overwrite #extract_links instead.
      def links
        @links ||= extract_links.select{|l| l.valid?}
      end

      # Should be overwritten.
      def property(key = nil)
        @properties ||= self.class.unserialize(@io)
        if key
          @properties[key]
        else
          @properties
        end
      end
      
      # Should return true if the current resource represented by this media-type can be designated with <tt>id</tt>.
      # Should be overwritten.
      def represents?(id)
        false
      end
      
      # Should be overwritten
      def collection?
        false
      end
      
      # An object to display on Resource#inspect.
      # Should be overwritten.
      def meta
        self.class.unserialize(@io)
      end

      # How to iterate over a collection
      # Should be overwritten
      def each(*args, &block)
        raise NotImplemented
      end

      
      protected
      def extract_links
        []
      end
    end

  end

end
