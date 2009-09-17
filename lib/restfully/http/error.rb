module Restfully
  module HTTP
    class Error < Restfully::Error
      attr_reader :response
      def initialize(response)
        @response = response
        if response.body.kind_of?(Hash)
          message = "#{response.status} #{response.body['title']}. #{response.body['message']}"
        else
          message = response.body
        end
        super(message)
      end
    end
    class ClientError < Restfully::HTTP::Error; end
    class ServerError < Restfully::HTTP::Error; end
  end
end
      
      