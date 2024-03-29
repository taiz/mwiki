require 'mwiki/webrick_cgi'
require 'mwiki/request'
require 'mwiki/handler'
require 'mwiki/response'
require 'pp'

module MWiki

  class MCGI < WEBrick::CGI
    def self.main(wiki)
      super({}, wiki)
    end

    def do_GET(req, res)
      wiki, = *@options
      
      request  = Request.new(req, wiki.locale)
      response = Handler.new(wiki).handle(request)
      response.update_for res
    end

    alias :do_POST :do_GET

  end

end
