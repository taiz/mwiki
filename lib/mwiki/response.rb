module MWiki

  class Response
    def self.new_from_page(page)
      res = new()
      res.set_content_body page.content, page.type, page.charset
      res
    end

    def initialize
      @status = nil
      @header = {}
      @body = nil
    end

    attr_accessor :status
    attr_reader :body

    def set_content_body(body, type, charset)
      @body = body
      @header['Content-Type'] = "#{type}; charset=#{charset}"
    end

    def content_type
      @header['Content-Type']
    end

    def update_for(webrickres)
      webrickres.status = @statuts if @status
      @header.each do |k, v|
        webrickres[k] = v
      end
      webrickres.body = @body
    end  
  end

end
