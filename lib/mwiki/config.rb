require 'mwiki/userconfig'

module MWiki

  FRONT_PAGE_NAME = 'FrontPage'
  HELP_PAGE_NAME = 'HelpPage'
  TMP_PAGE_NAME = 'tmp'
  class Config

    # parse config hash
    # check required, duplicate
    def initialize(config)
      UserConfig.parse(config, 'config') do |conf|
        @locale       = conf.get_required(:locale)
        @templatedir  = conf.get_required(:templatedir)
        # both of which must be set
        conf.select! :theme, :css_url
        @css_url      = conf[:css_url]
        @theme        = conf[:theme]
        faker = conf.get_required(:use_html_url)
        @html_url_p   = (faker ? true : false)
        @suffix       = '.html'
        @site_name    = conf[:site_name]
        @logo_url     = conf[:logo_url]
        @user_cgi_url  = conf[:cgi_url]
      end
    end

    attr_reader :locale
    attr_reader :templatedir
    attr_reader :site_name
    attr_reader :logo_url

    def css_url
      @css_url || "#{@user_cgi_url}/#{theme}.css"
    end

    def html_url?
      @html_url_p
    end

    def document_suffix
      @suffix
    end

  end
end

