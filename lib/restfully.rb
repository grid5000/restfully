require 'backports'
require 'yaml'
require 'restfully/error'
require 'restfully/parsing'
require 'restfully/http'
require 'restfully/http/adapters/rest_client_adapter'
require 'restfully/extensions'
require 'restfully/session'
require 'restfully/special_hash'
require 'restfully/special_array'
require 'restfully/link'
require 'restfully/resource'
require 'restfully/collection'


module Restfully
  VERSION = "0.5.9"
  class << self
    attr_accessor :adapter
  end
  self.adapter = Restfully::HTTP::Adapters::RestClientAdapter
end
