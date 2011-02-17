require 'json'

module Restfully
  module MediaType

    class ApplicationJson < AbstractMediaType
      set :signature, "application/json"
      set :parser, JSON
    end

    register ApplicationJson

  end

end
