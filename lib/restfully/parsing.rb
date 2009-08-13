require 'json'

module Restfully
  
  class ParserNotFound < RestfullyError; end
  
  module Parsing
    def parse(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers[:content_type] if object.respond_to?(:headers)
      case content_type
      when /^application\/json/i
        JSON.parse(object)
      else
        raise ParserNotFound, [object, content_type]
      end
    end
  
    def dump(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers[:content_type] if object.respond_to?(:headers)
      case content_type
      when /^application\/json/i
        JSON.dump(object)
      else
        raise ParserNotFound, [object, content_type]
      end
    end
  end
end