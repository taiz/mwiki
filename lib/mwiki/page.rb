require 'mwiki/textutils'
require 'mwiki/erbutils'
require 'mwiki/response'

module MWiki

  class Page
    def response
      Response.new_from_page(self)
    end
  end

  class ErbPage < Page
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

    def charset
      @config.locale.charset
    end

    def css_url
      @config.css_url
    end

    def last_modified
      nil
    end

    private

    def escape_url(str)
      escape_html(URI.escape(str))
    end

    def page_charset
      escape_url(@config.locale.charset)
    end

  end

  class WikiPage < ErbPage
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
        "#{cgi_url()}/#{escape_url(page_name)}#{@config.document_suffix}"
      else
        "#{cgi_url}?cmd=view&name=#{escape_url(page_name)}"
      end
    end

    def menu_deletable?; false; end
  end

  class NamedPage < WikiPage
    def initialize(config, page)
      super(config)
      @page = page
    end

    def compile_page(content)
      @page.syntax.compile(content, @page.name)
      #content
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
    def menu_deletable?; true; end

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
      compile_page(@page.source)
    end

    def css_url
      if @config.html_url?
      then "/#{@config.css_url}"
      else @config.css_url
      end
    end

    def menu_deletable?; true; end
  end

  class ListPage < WikiPage
    def initialize(config, pages)
      super(config)
      @pages = pages
    end

    def template_id
     'list'
    end

    def page_list
      #page_names = @pages.map {|p| p.name}
      #page_names.sort {|n1, n2| n1.downcase <=> n2.downcase}
      @pages.sort {|p1, p2| p1.name.downcase <=> p2.name.downcase}
    end
  end

  class EditPage < NamedPage
    def initialize(config, page)
      super
    end

    private

    def template_id
     'edit'
    end
    
    def body
      @page.source
    end

    def menu_deletable?
      unless @page.is_proxy?
      then true
      else false
      end
    end
  end

  class ThanksPage < WikiPage
    def initialize(config, page_name)
      super(config)
      @page_name = page_name
    end

    def template_id
      'thanks'
    end

    def page_view_url
      if @config.html_url?
        "#{cgi_url()}/#{escape_url(@page_name)}#{@config.document_suffix}"
      else
        "#{cgi_url()}?cmd=view;name=#{escape_url(@page_name)}"
      end
    end
  end

  class DeletePage < WikiPage
    def initialize(config, page_name)
      super(config)
      @page_name = page_name
    end

    attr_accessor :page_name

    def template_id
      'delete'
    end

    def page_view_url
      "#{cgi_url()}?cmd=list"
    end
  end

  class PreviewPage < NamedPage
    def initialize(config, page)
      super
      @text = page.source
    end

    private

    def template_id
     'preview'
    end

    def body
      @text
    end

    def compiled_body
      compile_page(@page.source)
      #@text
    end
  end

  class SearchResultPage < WikiPage
    def initialize(config, pages)
      super(config)
      @pages = pages
    end

    attr_reader :pages

    def template_id
     'search_result'
    end

  end

end
