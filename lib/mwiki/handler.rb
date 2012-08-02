module MWiki

  # Requestからパラメータを取り出して、cmdごとに各処理にディスパッチする
  # 処理の実装はWikiSpaceに委譲する
  class Handler
    inculde TextUtils

    def initialize(wiki)
      @wiki = wiki
    end
    
    def handle(req)
      _handle(req) || @wiki.view(FRONT_PAGE_NAME).response
    rescue Exception => err
      error_response(err)
    end

    def _handle(req)
      cmd = req.cmd || 'view'
      method = "handle_#{cmd}"
      send(method, req)
    end

    private

    def error_response(err)
      html  = "<html><head><title>Error</title></header><body>\n" +
              "<pre>MWiki Error\n"
      html << escape_html("#{err.message} (#{err.class})\n")
      html << escape_html(err.precise_message) << "\n" \
              if err.respond_to? :precise_message
      err.backtrace.each do |i|
        html << escape_html(i) << "\n"
      end
      html << "</pre></body></html>"

      #res = Response.new
      #res.set_content_body html, 'text/html', @wiki.locale.charset
      #res
    end

    def handle_view(req)
      page_name = req.page_name
      return nil unless page_name
      return nil unless @wiki.valid? page_name
      return nil unless @wiki.exist? page_name
      @wiki.view(page_name).response
    end

    def handle_edit(req)
      page_name = req.page_name
      return nil unless page_name
      return nil unless @wiki.valid? page_name
      return nil unless @wiki.exist? page_name
      @wiki.edit(page_name).response
    end

    def handle_create(req)
      page_name = req.page_name
      return nil unless page_name
      return handle_edit(req) if @wiki.exist? page_name
      @wiki.create(page_name).response
    end

    def handle_save(req)
      page_name = req.page_name
      return invalid_edit(req.normalized_text, :save_without_name) \
          unless page_name
      return invalid_edit(req.normalized_text, :invalid_page_name) \
          unless @wiki.valid?(page_name)
      return handle_preview(req) if req.preview?
      
      text = req.normalized_text
      @wiki.save(page_name, text)
    end

    def handle_preview(req)
      @wiki.preview(req.page_name, req.normalized_text).response
    end

    def handle_search(req)
      @wiki.search(req.search_query, req.search_regexps)
    rescue WrongQuery => err
      @wiki.search_error(req.search_query, err).response
    end
  end

end
