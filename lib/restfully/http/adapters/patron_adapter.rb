require 'restfully/http/adapters/abstract_adapter'
require 'patron'

module Restfully
  module HTTP
    module Adapters
      class PatronAdapter < AbstractAdapter
        
        def initialize(base_url, options = {})
          super(base_url, options)
        end
        
      end
    end
  end
end