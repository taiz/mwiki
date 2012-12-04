def mwiki_cgidir
  File.dirname(File.expand_path(__FILE__))
end

def setup_enviroment
  $KCODE = 'utf-8'
  $LOAD_PATH << "#{mwiki_cgidir}/lib"
end

def load_mwiki_context
  # set config
  config = MWiki::Config.new(
    :locale       => MWiki::Locale.new,
    :templatedir  => "#{mwiki_cgidir}/templates",
    :css_url      => "default.css",
    :site_name    => "MWikipedia",
    :cgi_url      => "/mwiki",
    :use_html_url => true
  )

  # set database
  database = MWiki::Database.new(
    :path         => "#{mwiki_cgidir}/pages"
  )

  # set wiki syntax
  syntax = MWiki::Syntax.new(config, database)

  MWiki::WikiSpace.new(config, database, syntax)
end

