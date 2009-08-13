class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)


module Restfully
  class RestfullyError < StandardError; end
end

require File.dirname(__FILE__)+'/restfully/parsing'
require File.dirname(__FILE__)+'/restfully/session'
require File.dirname(__FILE__)+'/restfully/special_hash'
require File.dirname(__FILE__)+'/restfully/special_array'
require File.dirname(__FILE__)+'/restfully/link'
require File.dirname(__FILE__)+'/restfully/resource'
require File.dirname(__FILE__)+'/restfully/collection'
