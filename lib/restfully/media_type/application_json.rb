require 'json'

module Restfully
  module MediaType

    class ApplicationJson < AbstractMediaType
      class JSONParser
        def self.load(io, *args)
          JSON.load(io)
        end
        def self.dump(object, *args)
          JSON.dump(object)
        end
      end
      set :signature, "application/json"
      set :parser, JSONParser
    end

  end

end
