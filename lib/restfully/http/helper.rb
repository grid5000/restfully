module Restfully
  module HTTP
    module Helper

      def sanitize_head(h = {})
        sanitized_headers = {}
        h.each do |key, value|
          sanitized_key = key.to_s.
            downcase.
            gsub(/[_-]/, ' ').
            split(' ').
            map{|word| word.capitalize}.
            join("-")
          sanitized_value = case value
          when Array 
            value.join(", ")
          else 
            value
          end
          sanitized_headers[sanitized_key] = sanitized_value
        end
        sanitized_headers
      end
    
      def sanitize_query(h = {})
        sanitized_query = {}
        h.each do |key,value|
          sanitized_query[key] = stringify(value)
        end
        sanitized_query
      end
      
      protected
      def stringify(value)
        case value
        when Hash
          h = {}
          value.each{|k,v| h[k] = stringify(v)}
          h
        when Array
          value.map!{|v| stringify(v)}
        else
          value.to_s
        end
      end
    
    end
  end
end
