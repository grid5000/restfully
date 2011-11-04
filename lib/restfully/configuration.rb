require 'yaml'

module Restfully
  class Configuration
    attr_reader :options
    
    def initialize(opts = {})
      @options = opts.symbolize_keys
    end

    def merge(config = {})
      if config.respond_to?(:to_hash)
        @options.merge!(config.to_hash.symbolize_keys) do |key, oldval, newval|
          case oldval
          when Array then oldval.push(newval).flatten.uniq
          when Hash then oldval.merge(newval)
          else newval
          end
        end
        self
      else
        raise ArgumentError, "Don't know how to merge #{config.class}."
      end
    end

    def to_hash
      @options
    end

    # Attempt to expand the configuration if a :configuration_file options is
    # present. Existing options take precedence over those defined in the
    # configuration file.
    def expand
      file = ENV['RESTFULLY_CONFIG'] || @options[:configuration_file]
      if file
        file = File.expand_path(file)
        if File.file?(file) && File.readable?(file)
          @options = self.class.load(file).merge(self).options
        end
      end
      self
    end

    def [](key)
      @options[key.to_sym]
    end

    def []=(key, value)
      @options[key.to_sym] = value
    end
    
    def delete(key)
      @options.delete(key.to_sym)
    end

    def self.load(file)
      if file.nil?
        raise ArgumentError, "file can't be nil"
      else
        new(YAML.load_file(File.expand_path(file)))
      end
    end
  end
end