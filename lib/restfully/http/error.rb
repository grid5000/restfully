module Restfully
  module HTTP
    class Error < Restfully::Error
      STATUS_CODES = {
        400 => "Bad Request",
        401 => "Authorization Required",
        403 => "Forbiden",
        406 => "Not Acceptable"        
      }
      
      attr_reader :response
      def initialize(response)
        @response = response
        response_body = response.body rescue response.raw_body
        if response_body.kind_of?(Hash)
          message = "#{response.status} #{response_body['title']}. #{response_body['message']}"
        else
          message = "#{response.status} #{STATUS_CODES[response.status] || (response_body[0..100]+"...")}"
        end
        super(message)
      end
    end
    class ClientError < Restfully::HTTP::Error; end
    class ServerError < Restfully::HTTP::Error; end
  end
end
      
      