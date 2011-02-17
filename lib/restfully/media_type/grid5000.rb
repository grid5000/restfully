require 'json'

module Restfully
  module MediaType
    class Grid5000 < AbstractMediaType

      set :signature, %w{
        grid
        site
        cluster
        node
        version
        collection
        timeseries
        versions
        user
        metric
        job
        deployment
        notification
      }.map{|n|
        "application/vnd.fr.grid5000.api.#{n}+json"
      }.push(
        "application/vnd.grid5000+json"
      )
      set :parser, JSON

      def extract_links
        (property("links") || []).map do |link|
          l = Link.new(
            :rel => link['rel'],
            :type => link['type'],
            :href => link['href'],
            :title => link["title"],
            :id => link["title"]
          )
        end
      end

      def collection?
        property("items") && property("total") && property("offset")
      end

      def meta
        if collection?
          property("items")
        else
          property
        end
      end

      def represents?(id)
        property("uid") == id.to_s || property("uid") == id.to_i
      end

      # Only for collections
      def each(*args, &block)
        (property("items") || []).map{|i|
          self.class.new(self.class.serialize(i))
        }.each(*args, &block)
      end

    end
    register Grid5000
  end
end
