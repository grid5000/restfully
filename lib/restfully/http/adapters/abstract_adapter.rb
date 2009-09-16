module Restfully
  module HTTP
    module Adapters
      
      class AbstractAdapter

        def initialize(base_url, options = {})
          @options = options.symbolize_keys
          @base_url = base_url
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
          raise NotImplementedError, "DELETEis not supported by your adapter."
        end
      end
      
    end
  end
end