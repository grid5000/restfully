require 'rack/utils'

module Restfully
  module MediaType
    
    class ApplicationXWwwFormUrlencoded < AbstractMediaType
      
      class Parser
        def self.load(object, *args)
          if object.respond_to? :to_str
            object = object.to_str
          elsif object.respond_to? :to_io
            object = object.to_io.read
          else
            object = object.read
          end
          ::Rack::Utils.parse_nested_query(object)
        end
        
        def self.dump(object, *args)
          ::Rack::Utils.build_nested_query(object)
        end
      end
      
      set :signature, "application/x-www-form-urlencoded"
      set :parser, Parser
    end
  
    register ApplicationXWwwFormUrlencoded
    
  end
  
end
