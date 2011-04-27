module Restfully
  module MediaType

    class Wildcard < AbstractMediaType
      class IdentityParser
        def self.load(object, *args)
          if object.respond_to? :to_str
            object = object.to_str
          elsif object.respond_to? :to_io
            object = object.to_io.read
          else
            object = object.read
          end
        end

        def self.dump(object, *args)
          object
        end
      end

      set :signature, "*/*"
      set :parser, IdentityParser
    end

  end

end
