class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)

# monkey patching:
class Hash
  # This is by no means the standard way to transform ruby objects into query parameters
  # but it is targeted at our own needs
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