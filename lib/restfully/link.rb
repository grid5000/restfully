module Restfully
  class Link
    
    VALID_RELATIONSHIPS = %w{member parent collection self alternate}
    RELATIONSHIPS_REQUIRING_TITLE = %w{collection member}
    
    attr_reader :rel, :title, :href, :errors
    
    def initialize(attributes = {})
      @rel = attributes['rel']
      @title = attributes['title']
      @href = attributes['href']
      @resolvable = attributes['resolvable'] || false
      @resolved = attributes['resolved'] || false
    end
    
    def resolvable?; @resolvable == true; end
    def resolved?; @resolved == true; end
    def self?; @rel == 'self'; end
    
    def valid?
      @errors = []
      if href.nil? || href.empty?
        errors << "href cannot be empty."
      end
      unless VALID_RELATIONSHIPS.include?(rel)
        errors << "#{rel} is not a valid link relationship."
      end
      if (!title || title.empty?) && RELATIONSHIPS_REQUIRING_TITLE.include?(rel)
        errors << "#{rel} #{href} has no title."
      end
      errors.empty?
    end
  end
end