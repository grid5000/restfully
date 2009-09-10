
module Restfully
  class RestfullyError < StandardError; end
end

require 'restfully/extensions'
require 'restfully/session'
require 'restfully/special_hash'
require 'restfully/special_array'
require 'restfully/link'
require 'restfully/resource'
require 'restfully/collection'
