$LOAD_PATH << "/Users/miyabetaiji/ruby/mwiki/lib"

require 'test/unit'
require 'pathname'
require './syntax'
require './config'
require './database'

class TestSyntax < Test::Unit::TestCase
  def setup
	  config = MWiki::Config.new(
	    :locale       => "dummy",
	    :templatedir  => "dummy",
	    :css_url      => "default.css",
	    :site_name    => "MWikipedia",
	    :cgi_url      => "/mwiki",
	    :use_html_url => true
	  )
    @page_path = "/Users/miyabetaiji/ruby/mwiki/pages"
	  database = MWiki::Database.new(
	    :path         => @page_path
	  )
	  @syntax = MWiki::Syntax.new(config, database)
  end

  def test_simple_escape
    assert_equal(%Q[dudada&amp;&gt;],
                 @syntax.text("dudada&>"))
  end

  def test_internal_link
    test_page = Pathname.new(@page_path) + "TestText"
    test_page.open('w'){}

    assert_equal(%Q[aaa <a href="/mwiki/TestText.html">TestText</a> bbb],
                 @syntax.text("aaa TestText bbb"))
    assert_equal(%Q[aaa <a href="/mwiki/TestText2.html" class="dangling">?</a>TestText2 bbb],
                 @syntax.text("aaa TestText2 bbb"))
  end

  def test_bracket_link
    # image link
    image_url = "http://docs.oracle.com/javafx/javafx/images/javafx-icon-getstarted.gif"
    assert_equal(
      %Q[aaa <img src="#{image_url}"> bbb],
      @syntax.text("aaa [[img:#{image_url}]] bbb"))

    # image inter
    inter_page = Pathname.new(@page_path) + "InterWikiName"
    id = "ruby-list"
    url = "http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/%s"
    file = "test.jpg"
    inter_page.open('w') do |f|
      f << "\n"
      f << "* #{id}:#{url}\n"
    end
    assert_equal(
      %Q[aaa <img src="#{url[0..-3]}#{file}"> bbb],
      @syntax.text("aaa [[img:#{id}:#{file}]] bbb"))

    # seems url
    assert_equal(
      %Q[aaa <img src="#{url[0..-3]}#{file}"> bbb],
      @syntax.text("aaa [[img:#{url[0..-3]}#{file}]] bbb"))
  end

  def test_seems_url
    url = "http://google.com"
    assert_equal(
      %Q[aaa <a href="#{url}">#{url}</a> bbb],
      @syntax.text("aaa #{url} bbb"))
  end
end

