module Rack
  class HTTPLogger
    def initialize(app, options = {})
      @@started ||= false
      @app = app
      @options = options
      @log_file = options[:log_file] || "restfully.log"
      unless @@started
        log(nil)
        @@started = true
      end
    end
    
    def log(msg)
      if msg == nil
        ::File.open(@log_file, "w+") do |f|
          f << "Session started at #{Time.now.to_s}:"
          f << "\n"
        end
      else
        ::File.open(@log_file, "a") do |f|
          f << msg
          f << "\n"
        end
      end
    end

    def call(env)
      req = Rack::Request.new(env)

      head = env.reject{|k,v| k !~ /^HTTP_/}.map{|(k,v)| 
        v = v.gsub(/^Basic .+\n?/, 'Basic XXX') if k == 'HTTP_AUTHORIZATION'
        [k.gsub("HTTP_", "").split("_").map(&:capitalize).join("-"), v].join(": ")
      }
      head.unshift "Host: #{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
      if ['PUT', 'POST'].include?(env['REQUEST_METHOD'])
        head << "Content-Type: #{env['CONTENT_TYPE']}"
      end
      path = if env['QUERY_STRING'].empty?
        env['PATH_INFO']
      else
        "#{env['PATH_INFO']}?#{env['QUERY_STRING']}"
      end

      msg = [
        "#{env['REQUEST_METHOD']} #{path} HTTP/1.1",
        head.join("\r\n")
      ]
      if ['PUT', 'POST'].include?(env['REQUEST_METHOD'])
        msg.push("", env['rack.input'].read)
        env['rack.input'].rewind
      end
      log "------"
      log(msg.join("\r\n"))

      code, head, body = @app.call(env)

      payload = ""
      body.each{|chunk| payload << chunk}

      msg = [
        "HTTP/1.1 #{code} #{RestClient::STATUSES[code]}",
        head.reject{|k,v| k =~ /^X-/i}.map{|(k,v)| [k,v].join(": ")}.join("\r\n"),
        "",
        payload
      ]
      log("\n")
      log(msg.join("\r\n"))

      body.rewind if body.respond_to?(:rewind)
      [code, head, body]
    end
  end
end

RestClient.enable Rack::HTTPLogger