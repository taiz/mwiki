require 'webrick/cgi'

module WEBrick

  class CGI
    def self.main(webrickconf, *context)
      cgi = new(webrickconf, *context)
      cgi.run
    end

    def self.each_request(&block)
      yield ENV, $stdin, $stdout
    end

    def run
      CGI.each_request do |env, stdin, stdout|
        start(env, stdin, stdout)
      end
    end
  end

end
