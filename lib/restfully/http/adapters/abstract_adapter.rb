module Restfully
  module HTTP
    module Adapters
      
      class AbstractAdapter
        attr_reader :logger, :options
        def initialize(base_uri, options = {})
          @options = options.symbolize_keys
          @logger = @options.delete(:logger) || Restfully::NullLogger.new
          @base_uri = base_uri
        end
        
        def get(request)
          raise NotImplementedError, "GET is not supported by your adapter."
        end
        def post(request)
          raise NotImplementedError, "POST is not supported by your adapter."
        end
        def put(request)
          raise NotImplementedError, "PUT is not supported by your adapter."
        end
        def delete(request)
          raise NotImplementedError, "DELETE is not supported by your adapter."
        end
      end
      
    end
  end
end