require 'restfully/media_type/abstract_media_type'

module Restfully
  module MediaType
    class << self
      def catalog
        @catalog ||= Set.new
      end

      def find(*types)
        return nil if types.compact.empty?

        found = {}

        catalog.each{ |media_type|
          match = media_type.supports?(*types)
          found[match] = media_type unless match.nil?
        }

        if found.empty?
          nil
        else
          found.sort{|a, b| a[0].length <=> b[0].length }.last[1]
        end
      end


      def unregister(media_type)
        catalog.delete(media_type)
        build_index
        self
      end

      def register(media_type)
        if media_type.signature.empty?
          raise ArgumentError, "The given MediaType (#{media_type}) has no signature"
        end
        if media_type.parser.nil?
          raise ArgumentError, "The given MediaType (#{media_type}) has no parser"
        end
        unregister(media_type).catalog.add(media_type)
      end

      # Reset the catalog to the default list of media types
      def reset
        %w{
          wildcard
          application_json
          application_x_www_form_urlencoded
          grid5000
        }.each do |m|
          require "restfully/media_type/#{m}"
          register MediaType.const_get(m.camelize)
        end
      end

      def build_index
        # @index = []
        # catalog.each do |media_type|
        #
        # end
      end


    end

    reset

  end
end
