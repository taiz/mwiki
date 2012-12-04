$LOAD_PATH << "/Users/miyabetaiji/ruby/mwiki/lib"

require 'test/unit'
require './syntax'

class TestSyntax < Test::Unit::TestCase
  def setup
    @syntax = MWiki::Syntax.new(0,0)
  end

  def test_caption
    body = " dudada roemrgr"
    line = "===#{body}"
    p line
    
    assert_equal("<h3>#{body.strip}</h3>", @syntax.compile(line, ""))
  end

  def test_ul
    line =  ""
    line << "* ABC\n"
    line << "* DEF\n"
    line << "  GHI\n"
    line << "* JKL\n"
    line << " * MNO\n"
    line << "   * PQR\n"
    line << " * STU\n"
    line << "* VWX\n"

    puts @syntax.compile(line, "")
  end

  def test_dl
    line = ""
    line << ":dudada\n"
    line << " 20 years old\n"
    line << " he will be live over 50 yeras...\n"
    line << ":nezumi\n"
    line << " he came from N.Y. but he is musuborasii\n"

    puts @syntax.compile(line, "")
  end

  def test_cite
    line =  ""
    line << "\"\"dudada is 20 years old.\n"
    line << "\"\"but he is foolish and never grow up...\n"

    puts @syntax.compile(line, "")
  end

=begin
  def test_pre
    line =  ""
    line << "{{{\n"
    line << "dudada is 20 years old.\n"
    line << "he want to live over 50 years... but anyone don't want.....\n"

    puts @syntax.compile(line, "")
  end
=end

  def test_indented_pre
    line =  ""
    line << "   dudada is 20 years old.\n"
    line << "   he want to live over 50 years... but anyone don't want.....\n"

    puts @syntax.compile(line, "")
  end

=begin
  def test_table
    line =  "|||h1|||h2|||h3|||h4\n"
    line << "||abc||def||ghi||aaa\n"
    line << "||jkl||mno\n"
    line << "||pqr||stu||\n"
    line << "||vwx\n"

    puts @syntax.compile(line, "")
  end
=end

  def test_table_csv
    line =  ""
    line << ",abc,def,ghi,aaa\n"
    line << ",jkl,mno\n"
    line << ",pqr,stu,\n"
    line << ",vwx\n"

    puts @syntax.compile(line, "")
  end

  def test_patagraph
    line =  ""
    line << "abc\n"
    line << "def\n"
    line << "hij\n"

    assert_equal(
      "<p>\n" + line.strip + "</p>\n",
      @syntax.compile(line, "")
    )
      
  end

end

