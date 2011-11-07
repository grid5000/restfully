require 'uri'
module Restfully
  class Link

    attr_reader :rel, :title, :href, :errors, :type

    def initialize(attributes = {})
      attributes = attributes.symbolize_keys
      @rel = attributes[:rel]
      @title = attributes[:title] || @rel
      @href = URI.parse(attributes[:href].to_s)
      @type = attributes[:type]
      @id = attributes[:id]
    end

    def self?; @rel == 'self'; end

    def types
      type.split(";")
    end

    def valid?
      @errors = []
      if href.nil?
        errors << "href cannot be nil"
      end
      errors.empty?
    end

    def media_type
      @media_type ||= MediaType.find(type)
    end # def catalog
    
    def id
      title.to_s.downcase.gsub(/[^a-z]/,'_').squeeze('_').to_sym
    end

  end # class Link
end
