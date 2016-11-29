require 'json'

module Restfully
  module MediaType
    class Grid5000 < AbstractMediaType

      set :signature, %w{
        grid
        site
        cluster
        node
        nodestatus
        version
        collection
        timeseries
        versions
        user
        metric
        job
        deployment
        networkequipment
        environment
        notification
      }.map{|n|
        "application/vnd.fr.grid5000.api.#{n}+json"
      }.unshift(
        "application/vnd.grid5000.collection+json"
      ).unshift(
        "application/vnd.grid5000.item+json"
      )
      set :parser, ApplicationJson::JSONParser

      def extract_links
        (property.delete("links") || []).map do |link|
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
        !!(property("items") && property("total") && property("offset"))
      end

      def direct_fetch_uri(symbol)
        self_link = links.find{|l| l.self?}
        return nil if self_link.nil?
        URI.parse([self_link.href, symbol.to_s].join("/"))
      end

      def meta
        if collection?
          property("items")
        else
          property
        end
      end

      def represents?(id)
        id = id.to_s
        property("uid") == id || property("uid") == id.to_i
      end

      # Only for collections
      def each(*args, &block)
        (property("items") || []).map{|i|
          self.class.new(self.class.serialize(i), @session)
        }.each(*args, &block)
      end

    end

  end
end
