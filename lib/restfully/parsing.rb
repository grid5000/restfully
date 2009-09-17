require 'json'

module Restfully
  
  module Parsing
  
    class ParserNotFound < Restfully::Error; end
    def unserialize(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers['Content-Type'] if object.respond_to?(:headers)
      case content_type
      when /^application\/json/i
        JSON.parse(object)
      else
        raise ParserNotFound.new("Content-Type '#{content_type}' is not supported. Cannot parse the given object.")
      end
    end
  
    def serialize(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers['Content-Type'] if object.respond_to?(:headers)
      case content_type
      when /^application\/json/i
        JSON.dump(object)
      else
        raise ParserNotFound, [object, content_type]
      end
    end

  end
end