require 'pathname'
require 'mwiki/userconfig'
require 'pp'

module MWiki

  class Database

    def initialize(config, syntax = nil)
      UserConfig.parse(config, 'databae') do |conf|
        @root_path = conf.get_required(:path)
      end
      dir = Pathname.new(@root_path)
      dir.mkpath unless dir.exist?

      @syntax = nil
    end
    attr_accessor :syntax

    def valid?(name)
      not invalid?
    end

    def exist?(name)
      File.exist?(fspath(name))
    end

    def find(name)
      PageEntry.new(get_path(name), @syntax)
    end

    def create(name)
      f = open(fspath(name), 'w')
      f.close
    end

    def find_all(query, regexps)
      hits = {}
      Pathname.new(@root_path).children.each do |path|
        next unless path.file?
        regexps.each do |r|
          hit = grep(path, r)
          next if hit.empty?
          hits[path.basename.to_s] = hit.first
        end
      end
      hits
    end

	  private
	
    def fspath(name)
      "#{@root_path}/#{name}"
    end

    def get_path(name)
      Pathname.new(fspath(name))
    end

	  def grep(path, regexp)
	    hits = []
	    path.each_line do |line|
	      hits << line.chomp if regexp =~ line
	    end
	    hits
	  end

    # file does not exist or file is not readble
    def invalid(name)
      return false unless exist?(name)
      path = get_path(name)
      return false unless path.file? or path.readable?
    end

  end

  # Page source and page attriutes
  class PageEntry

      def initialize(path, syntax)
        @path   = path
        @syntax = syntax
      end
      attr_reader :syntax

      def name
        path.base_name.to_s
      end

      def size
        @path.size()
      end

      def mtime
        @path.mtime()
      end

      def source
        @path.read
      end

      def source= (text)
        @text = text
      end

      def save
        @path.open('w') {|f| f << (@text || source)}
      end

      def readonly?
        not @path.writable?
      end

  end

end

