
module Restfully  
  class Error < StandardError; end
  class NotImplemented < Error; end
  class MethodNotAllowed < Error; end
end