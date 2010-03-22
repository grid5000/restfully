

module Restfully
  
  module Parsing
    
    class ParserNotFound < Restfully::Error; end
    
    PARSERS = [
      {
        :supported_types => [/^application\/.*?json/i], 
        :parse => lambda{|object, options| 
          require 'json'
          JSON.parse(object)
        }, 
        :dump => lambda{|object, options|
          require 'json' 
          JSON.dump(object)
        },
        :object => true
      },
      {
        :supported_types => [/^text\/.*?(plain|html)/i], 
        :parse => lambda{|object, options| object}, 
        :dump => lambda{|object, options| object}
      },
      { # just store the binary data in a 'raw' property
        :supported_types => ["application/zip"],
        :parse => lambda{|object, options| {'raw' => object}},
        :dump => lambda{|object, options| object['raw']}
      }
    ]
    
    def unserialize(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers['Content-Type'] if object.respond_to?(:headers)
      parser = select_parser_for(content_type)
      if parser
        parser[:parse].call(object, options)
      else
        raise ParserNotFound.new("Cannot find a parser to parse '#{content_type}' content.")
      end
    end
  
    def serialize(object, options = {})
      content_type = options[:content_type]
      content_type ||= object.headers['Content-Type'] if object.respond_to?(:headers)
      parser = select_parser_for(content_type)
      if parser
        parser[:dump].call(object, options)
      else
        raise ParserNotFound.new("Cannot find a parser to dump object into '#{content_type}' content.")
      end
    end
    
    def select_parser_for(content_type)
      raise ParserNotFound.new("The Content-Type HTTP header of the resource is empty. Cannot find a parser.") if content_type.nil? || content_type.empty?
      content_type.split(",").each do |type|
        parser = PARSERS.find{|parser| parser[:supported_types].find{|supported_type| type =~ (supported_type.kind_of?(String) ? Regexp.new(supported_type) : supported_type) }}
        return parser unless parser.nil?
      end
      nil
    end

  end
end