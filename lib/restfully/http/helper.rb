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
    
    end
  end
end
