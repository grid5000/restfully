require 'base64'

module Restfully
  module Rack
    class BasicAuth
      def initialize(app, username, password)
        @app = app
        @username = username
        @password = password
      end
      
      def call(env)
        env['HTTP_AUTHORIZATION'] = [
          "Basic",
          Base64.encode64([
            @username,
            @password
          ].join(":"))
        ].join(" ")
        
        @app.call(env)
      end
      
    end # class BasicAuth
  end # module Rack
end
