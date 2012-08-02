module MWiki
  class Page
  end

  class RhtmlPage < Page
    include TextUtils
    include ErbUtils

    def initialize(config)
      @config = config
    end

    def content
      run_erb(@config.templatedir, template_id)
    end

    def type
      'text/html'
    end

    def css_url
      @config.css_url
    end

    private

    def escape_url(str)
      escape_html(URI.escape(str))
    end

  end

  class WikiPage < RhtmlPage
    def initialize(config)
      super(config)
    end

    def cgi_url
      escape_url(@config.cgi_url)
    end

    def logo_url
      u = @config.logo_url
      u ? %[<img class="sitelogo" src="#{escape_html(u)}" alt=""> ] : ''
    end

    def view_url(page_name)
      if @config.html_url?
        "#{escape_url(page_name)}#{@config.document_suffix}"
      else
        "#{cgi_url}?cmd=view;name=#{escape_url(page_name)}"
      end
    end
  end

  class NamedPage < WikiPage
    def initialize(config, page)
      super(config)
      @page = page
    end

    def compile_page(content)
      @page.syntax.compile(content, @page.name)
    end

    def page_name
      escape_html(@page.name)
    end

    def page_url
      escape_url(@page.name)
    end

    def page_view_url
      view_url(@page.name)
    end

    def front_page?
      @page.name == FRONT_PAGE_NAME
    end

    def site_name
      escape_html(@config.site_name || FRONT_PAGE_NAME)
    end

    def logo_url
      u = @config.logo_url
      u ? %[<img class="sitelogo" src="#{escape_html(u)}" alt=""> ] : ''
    end

  end

  class ViewPage < NamedPage
    def initialize(config, page)
      super
    end

    def last_modified
      mtime()
    end

    private

    def template_id
     'view'
    end
    
    def body
      compile_page(@page.soruce)
    end
  end

  class ViewPage < NamedPage
    def initialize(config, page)
      super
    end

    def last_modified
      mtime()
    end

    private

    def template_id
     'view'
    end
    
    def body
      compile_page(@page.soruce)
    end
  end

end
