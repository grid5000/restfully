class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)

# monkey patching:
class Hash
  # Taken from ActiveSupport
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  # Taken from ActiveSupport  
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end


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