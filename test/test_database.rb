$LOAD_PATH << "/Users/miyabetaiji/ruby/mwiki/lib"

require 'test/unit'
require './database'

class TestDatabase < Test::Unit::TestCase
  def setup
    @db = MWiki::Database.new(:path => 'test')
    @f1 = open('test/duda', 'w') do |f|
      f << "ngaaa\n"
      f << "ngooo\n"
    end
    @f2 = open('test/nezumi', 'w') do |f|
      f << "ngrururun\n"
    end
  end

  def test_exit_must_be_true
    assert(@db.exist?('duda'))
  end

  def test_exit_must_be_false
    assert(!@db.exist?('dudada'))
  end

  def test_find
    page = @db.find('duda')
    assert (page != nil)
    assert_equal("ngaaa\nngooo\n", page.source)
    assert_equal(12, page.size)
    assert (! page.readonly?)
  end

  def test_save
    page = @db.find('duda')
    page.source = "nezumi\n"
    page.save
    page = @db.find('duda')
    assert_equal("nezumi\n", page.source)
  end

  def test_create
    @db.create('nezumi')
    assert @db.exist?('nezumi')
  end

  def test_find_all
    hits = @db.find_all('ng', [/ng/i])
    assert_equal({'duda' => 'ngaaa', 'nezumi' => 'ngrururun'}, hits)
  end

end
