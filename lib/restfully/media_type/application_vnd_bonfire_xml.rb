require 'xml'

module Restfully
  module MediaType
    class ApplicationVndBonfireXml < AbstractMediaType
      NS = "http://api.bonfire-project.eu/doc/schemas/occi"
      HIDDEN_TYPE_KEY = "__type__"

      def collection?
        !!(property("items") && property("total") && property("offset"))
      end

      class Parser
        class << self
          def load(io, *args)
            if io.respond_to?(:read)
              io = io.read
            end
            xml = XML::Document.string(io.to_s)
            h = load_xml(xml.root)
            h[HIDDEN_TYPE_KEY] = if h['items']
              if xml.root.attributes["href"]
                xml.root.attributes["href"].
                split("/").last.gsub(/s$/,'')+"_collection"
              elsif h['items'].length > 0
                h['items'][0][HIDDEN_TYPE_KEY]
              else
                nil
              end
            else
              xml.root.name
            end
            h
          end


          def dump(object, opts = {})
            root_name = if opts[:serialization]
              opts[:serialization][HIDDEN_TYPE_KEY].gsub(/\_collection$/,'')
            elsif object[HIDDEN_TYPE_KEY]
              object[HIDDEN_TYPE_KEY]
            end
            fail "Can't infer a root element name for object: #{object.inspect}" if root_name.nil?
            xml = XML::Document.new
            xml.root = XML::Node.new(root_name)
            xml.root["xmlns"] = NS
            dump_object(object, xml.root)
            xml.to_s
          end

          protected

          def load_xml(element)
            h = {}


            element.each_element do |e|
              next if e.empty?
              if e.name == 'items' && element.name == 'collection'
                h['total'] = e.attributes['total'].to_i
                h['offset'] = e.attributes['offset'].to_i
                h['items'] = []
                e.each_element do |e2|
                  h['items'] << load_xml(e2).merge(HIDDEN_TYPE_KEY => e2.name)
                end
                # if no total specified, total equals the number of items
                h['total'] = h['items'].length if h['total'] == 0
              else
                load_xml_element(e, h)
              end
            end
            if element.attributes["href"]
              h["id"] ||= element.attributes["id"] if element.attributes["id"]
              h["name"] ||= element.attributes["name"] if element.attributes["name"]
              h["link"] ||= []
              h["link"].push({
                "href" => element.attributes["href"],
                "rel" => "self"
              })
            end
            h
          end

          # We use <tt>HIDDEN_TYPE_KEY</tt> property to keep track of the root
          # name.
          def load_xml_element(element, h)
            if element.attributes? && href = element.attributes.find{|attr|
              attr.name == "href"
            }
              single_or_array(h, element.name, element.attributes.inject({}) {|memo, attr| memo[attr.name] = attr.value; memo})
              #build_resource(href.value))
            else
              if element.children.any?(&:element?)
                # This includes ["computes", "networks", "storages"] section
                # of an experiment.
                if element.children.select(&:element?).map{|c|
                   c.name
                }.all?{|n| 
                  "#{n}s" == element.name
                }
                  element.each_element {|e| 
                    e.name = element.name
                    load_xml_element(e, h)
                  }
                else
                  single_or_array(h, element.name, load_xml(element))
                end
              else
                value = element.content.strip
                unless value.empty?
                  single_or_array(h, element.name, value)
                end
              end
            end
          end

          def single_or_array(h, key, value)
            if h.has_key?(key)
              if h[key].kind_of?(Array)
                h[key].push(value)
              else
                h[key] = [h[key], value]
              end
            elsif ["disk", "nic", "link", "computes", "networks", "storages", "endpoint", "site_link", "interface", "network_link"].include?(key)
              h[key] = [value]
            else
              h[key] = value
            end
          end

          # def build_resource(uri)
          #   uri
          # end

          def dump_object(object, parent)
            case object
            when XML::Node
              parent << object
            when Restfully::Resource
              dump_object({"href" => object.uri.to_s}, parent)
            when Hash
              object.stringify_keys!
              if object.has_key?("href") || (
                # or object.keys == ["name"] && parent.parent &&
                # parent.parent.parent
                ["save_as"].include?(parent.name)
              )
                # only attributes
                object.each{|kattr,vattr|
                  parent.attributes[kattr.to_s] = vattr
                }
              else
                object.each do |k,v|
                  next if k == HIDDEN_TYPE_KEY
                  node = XML::Node.new(k.to_s)
                  parent << node
                  dump_object(v, node)
                end
              end
            when Array
              i = 0
              parent['id'] = i.to_s
              dump_object(object[0], parent)
              (object[1..-1] || []).each{|item|
                i+=1
                node = XML::Node.new(parent.name)
                node['id'] = i.to_s
                dump_object(item, node)
                parent.parent << node
              }
            else
              parent << object.to_s
            end
          end
        end
      end

      set :signature, "application/vnd.bonfire+xml"
      set :parser, Parser

      def extract_links
        (property.delete("link") || []).map do |link|
          l = Link.new(
            :rel => link['rel'],
            :type => link['type'] || self.class.default_type,
            :href => link['href'],
            :title => link["title"],
            :id => link["title"]
          )
        end
      end

      def represents?(id)
        property("id") == id.to_s || property("name") == id.to_s || links.find{|l| l.self? && l.href.to_s.split("/").last == id.to_s}
      end
      
      def complete?
        if property.reject{|k,v| [HIDDEN_TYPE_KEY, "id", "name"].include?(k)}.empty? && links.find(&:self?)
          false
        else
          true
        end
      end
      
      def banner
        if property("name")
          " name=#{property("name").inspect}"
        end
      end

      # Only for collections
      def each(*args, &block)
        @items ||= (property("items") || []).map{|i|
          self.class.new(self.class.serialize(i), @session)
        }
        @items.each(*args, &block)
      end

    end

    register ApplicationVndBonfireXml
  end
end
