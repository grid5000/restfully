require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array'
require 'yaml'

require 'restfully/version'
require 'restfully/configuration'
require 'restfully/error'
require 'restfully/http'
require 'restfully/link'
require 'restfully/resource'
require 'restfully/collection'
require 'restfully/rack'
require 'restfully/session'
require 'restfully/media_type'

module Restfully
  DEFAULT_TAPE = "restfully-tape"
  DEFAULT_URI = "http://localhost:4567"
  # Include the default media-types
  MediaType.reset
end
