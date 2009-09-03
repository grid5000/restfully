class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)

# monkey patching:
class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def to_params
    params = ''

    each do |k, v|
      if v.is_a?(Array)
        params << "#{k}=#{v.join(",")}&"
      else
        params << "#{k}=#{v.to_s}&"
      end
    end

    params.chop! 
    params
  end

end

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
