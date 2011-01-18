class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)

class Object
  # Taken from ActiveSupport
  def to_query(key)
    require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
    "#{CGI.escape(key.to_s)}=#{CGI.escape(to_params.to_s)}"
  end
  
  def to_params
    to_s
  end
end

class Hash
  # Converts a hash into a string suitable for use as a URL query string. 
  # An optional <tt>namespace</tt> can be passed to enclose the param names.
  # Taken from ActiveSupport
  def to_params(namespace = nil)
    collect do |key, value|
      value.to_query(namespace ? "#{namespace}[#{key}]" : key)
    end * '&'
  end
end

class Array
  # Taken from ActiveSupport
  def to_query(key)
    prefix = "#{key}[]"
    collect { |value| value.to_query(prefix) }.join '&'
  end
end