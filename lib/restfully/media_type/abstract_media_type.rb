require 'set'

module Restfully
  module MediaType

    class AbstractMediaType

      # 
      # These class functions should NOT be overwritten by descendants.
      # 
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
        
        # Returns the media-type signature, i.e. the list of metia-type it
        # supports.
        def signature
          [(defaults[:signature] || [])].flatten
        end
        
        # Returns the media-type parser.
        def parser
          defaults[:parser]
        end
        
        # Returns the media-type default signature.
        def default_type
          signature.first
        end
        
        # Returns the first supported media-type of the signature that matches
        # one of the given <tt>types</tt>.
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
        
        # Serialize an object into a String.
        # Calls parser#dump.
        def serialize(object, *args)
          case object
          when String
            object
          else
            parser.dump(object, *args)
          end
        end
        
        # Unserialize an io object into a Hash.
        # Calls parser#load.
        def unserialize(io, *args)
          parser.load(io, *args)
        end
        
      end
      
      
      attr_reader :io, :session

      # A MediaType instance takes the original io object and the current
      # session object as input.
      def initialize(io, session)
        @io = io
        @session = session
      end

      # Returns a direct URI to a specific resource identified by <tt>symbol</tt>.
      # Only called from collections, when doing collection[:'some-resource-id'].
      # Either return a path if the media type supports direct fetching, or nil (default).
      def direct_fetch_uri(symbol)
        nil
      end

      # Returns an array of Link objects.
      # Do not overwrite directly. Overwrite #extract_links instead.
      def links
        @links ||= extract_links.select{|l| l.valid?}
      end

      # Returns the unserialized version of the io object.
      def unserialized
        @unserialized ||= self.class.unserialize(@io)
      end
      
      # Returns a string to display after the URI when pretty-printing
      # objects.
      def banner
        nil
      end

      # Without argument, returns the properties Hash obtained from calling
      # #unserialized.
      # With an argument, returns the value corresponding to that key.
      #
      # Should be overwritten if required.
      def property(key = nil)
        @properties ||= unserialized
        if key
          @properties[key]
        else
          @properties
        end
      end
      
      # Should return true if the current resource represented by this
      # media-type can be designated with <tt>id</tt>.
      #
      # Should be overwritten.
      def represents?(id)
        false
      end
      
      # Returns true if the current io object must be handled as a Collection.
      # 
      # Should be overwritten.
      def collection?
        false
      end
      
      # Returns true if the current io object is completely loaded.
      # Overwrite and return false to force a reloading if your object is just
      #  a URI reference.
      def complete?
        true
      end
      
      # An object to display on Resource#inspect.
      #
      # Should be overwritten.
      def meta
        property
      end

      # How to iterate over a collection
      #
      # Should be overwritten.
      def each(*args, &block)
        raise NotImplemented
      end

      
      protected
      # The function that returns the array of Link object.
      #
      # Should be overwritten.
      def extract_links
        []
      end
    end

  end

end
