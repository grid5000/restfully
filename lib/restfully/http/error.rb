module Restfully
  module HTTP
    class Error < Restfully::Error; end
    class ClientError < Restfully::HTTP::Error; end
    class ServerError < Restfully::HTTP::Error; end
  end
end
      
      