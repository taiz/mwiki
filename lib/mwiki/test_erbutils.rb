require 'test/unit'
require './erbutils'

class TestErbUtils < Test::Unit::TestCase
  include MWiki::ErbUtils

  def setup
    # create test file
    @templdir  = "../../templates"
    @templfile_v = "../../templates/view.rhtml"
    @templfile_e = "../../templates/edit.rhtml"
  end

  def test_simple_template
    File.open(@templfile_v, 'w') do |f|
      f << "abc\n"
    end
    assert_equal("abc\n", run_erb(@templdir, "view"))
  end

  def test_nest_define
    File.open(@templfile_v, 'w') do |f|
      f << "abc\n"
      f << ".include edit\n"
    end
    File.open(@templfile_e, 'w') {|f| f << "def"}
    assert_equal("abc\ndef\n", run_erb(@templdir, "view"))
  end
end
