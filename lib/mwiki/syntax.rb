require 'stringio'
require 'mwiki/textutils'
require 'csv'
require 'uri'

module MWiki

  class Syntax
    include MWiki::TextUtils

    def initialize(config, db )
      @config = config
      @db = db
      @result = ""
      @indent_stack = [0]
    end

    def compile(str, page_name)
      @f = LineInput.new(StringIO.new(str))
      @page_name = page_name
      do_compile(str)
      @result
    end
  
    CAPTION   = /\A(?:={2,4}|!{1,4})/
    UL        = /\A\s*\*|\A-/                # ^-xxx or ^ *xxx
    OL        = /\A\s*\(\d+\)|\A\#/          # ^ (1) or ^#
    DL        = /\A:/
    CITE      = /\A""|\A>/
    TABLE     = /\A,|\A\|\|/
    PRE       = /\A\{\{\{/
    INDENTED  = /\A\s+\S/

    PATAGRAPH_END = Regexp.union(
      CAPTION, UL, OL, CITE, TABLE, PRE, INDENTED
    )

    def do_compile(str)
      while @f.next?
        case @f.peek
        when CAPTION  then caption @f.gets
        when UL       then ul
        when OL       then ol
        when DL       then dl
        when CITE     then cite
        when TABLE    then table
        when PRE      then pre
        when INDENTED then indented
        else
          if @f.peek.strip.empty?
            @f.gets
            next
          end
          patagraph
        end
      end
    end

    def caption(line)
      head = line[/\A([=!]+)/, 1]
      if head[0,1] == "!"
        level = head.length + 1
      else
        level = head.length
      end
      str = line.sub(/\A[!=]+/,'').strip
      @result << "<h#{level}>#{str}</h#{level}>\n"
    end

    def patagraph
      @result << "<p>\n"
      nl = ''
      @f.until_match(PATAGRAPH_END) do |line|
        @result << nl + text(line.sub(/\A\~/,'').strip)
        nl = "\n"
      end
      @result << "</p>\n"
    end

    def ul
      xlist 'ul', UL
    end

    def ol
      xlist 'ol', OL
    end

    # example:input
    # - A
    #   - B
    # - C
    #   D
    # - E

    # example:output
    # <ul>
    # <li>A
    #   <ul>
    #     <li>B
    #   </ul>
    # </li>
    # <li>C

    LI_CONTINUE = {
      'ul' => /\A\s+[^\s\*]/,
      'ol' => /\A\s+(?!\(\d+\)|\#)\S/
    }    

    def xlist(type, mark_re)
      @result << "<#{type}>\n"

      # インデントを初期化する
      push_indent(indentof(@f.peek)) {
        @f.while_match(mark_re) do |line|
          # 1.ネストからの戻り
          if indent_shallower?(line)
            @f.ungets line
            break
          end
          # 2.ネスト
          if indent_deeper?(line)
            @f.ungets line
            xlist(type, mark_re)
            @result << "</li>\n"
            next
          end
          # 3.同階層
          buf = line.sub(mark_re, '').strip
          @f.while_match(LI_CONTINUE[type]) do |line|
            buf << "\n" + line.strip
          end
          if @f.next? and next_line_is_nested_list(mark_re)
            @result << "<li>#{text(buf)}\n"
          else
            @result << "<li>#{text(buf)}</li>\n"
          end
        end
      }
      @result << "</#{type}>\n"
    end

    def next_line_is_nested_list(mark_re)
      line = @f.peek
      mark_re =~ line and indent_deeper?(line)
    end

    def dl
      @result << "<dl>\n"
      @f.while_match(DL) do |line|
        #if /\A:|\A\s*\z/ =~ @f.peek.to_s
        #  # original wiki style
        #  _, dt, dd = line.strip.split(/\s*:\s*/, 3)
        #  @result << "<dt>#{dt}</dt><dd>#{dd.to_s}</dd>\n"
        #end
        dt = line.sub(DL, '')
        dd = ""
        @f.while_match(/\A\s+\S/) do |linei|
          dd << linei.strip << "\n"
        end
        @result << "<dt>#{text(dt)}</dt>\n<dd>#{text(dd.strip)}</dd>\n"
      end
      @result << "</dl>\n"
    end

    def cite
      @result << "<blockquote>"
      @result << "<p>"
      nl = ""
      @f.while_match(CITE) do |line|
        content = line.sub(CITE, '').strip
        if line.strip.empty?
          @result << "<p>\n<p>"
          nl = ""
        else
          @result << nl + escape_html(content)
          nl = "\n"
        end
      end
      @result << "<p>"
      @result << "</blockquote>\n"
    end

    def table
      case @f.peek
      when /\A\|/ then bar_table
      when /\A,/  then csv_table
      end
    end

    def bar_table
      # \\,a,||,b||,c ...
      buf = []
      @f.while_match(/\A\|\|/) do |line|
        # headerかdataかをチェックする
        cols = line.strip.split(/(\|\|\|?)/, -1)
        cols.shift
        row = []
        until cols.empty?
          isheader = (cols.shift == '|||')
          row << [cols.shift, isheader]
        end
        buf << row
      end
      output_table adjust_ncols(buf)
    end

    def csv_table
      buf = []
      @f.while_match(/\A,/) do |line|
        row = CSV.parse_line(line)[1..-1].map {|col| [col.to_s, false]}
        buf << row
      end
      output_table adjust_ncols(buf)
    end

    def adjust_ncols(rows)
      rows.each do |cols|
        while cols.last and cols.last[0].strip.empty?
          cols.pop
        end
      end
      n_maxcols = rows.map {|cols| cols.size}.max
      rows.each do |cols|
        cols.concat([['', false]] * (n_maxcols - cols.size))
      end
      rows
    end

    def output_table(rows)
      @result << "<table>\n"
      rows.each do |cols|
        @result << "<tr>\n" +
          cols.map do |col, isheader|
            if isheader
            then "<th>#{text(col.strip)}</th>\n"
            else "<td>#{text(col.strip)}</td>\n"
            end
          end.join('') +
          "</tr>"
      end
      @result << "</table>\n"
    end

    def pre
      @f.gets
      @result << "<pre>\n"
      @f.until_terminator(/\A\}\}\}/) do |line|
        @result << escape_html(line.rstrip) << "\n"
      end
      @result << "</pre>\n"
    end

    def indented
      buf = []
      # 先頭空白以外が開始されるまで続ける
      @f.until_match(/\A\S/) do |line|
        buf << line
      end
      # 末尾の空行を取り除く
      while buf.last.strip.empty?
        buf.pop
      end
      # インデントの最小値を求める。ただしゼロは除く
      minindent = buf.map {|line| indentof(line)}.reject {|i| i == 0}.min
      # 空行の場合空白をセット、通常行の場合インデントを戻してセット
      @result << "<pre>\n"
      buf.each do |line|
        if line.rstrip.empty?
          @result << ''
        else
          @result << escape_html(unindent(line.rstrip, minindent))
        end
      end
      @result << "</pre>\n"
    end

    #
    # indent
    #
    def push_indent(n)
      raise "shollower indent pushed: #{@indent_stack.inspect}" \
        unless n >= current_indent()
      @indent_stack.push n
      yield
    ensure
      @indent_stack.pop
    end

    def current_indent
      @indent_stack.last
    end

    def indentof(line)
      detab(line.slice(/\A\s*/)).length
    end

    def indent_shallower?(line)
      current_indent() > indentof(line)
    end

    def indent_deeper?(line)
      current_indent() < indentof(line)
    end

    INDENT_RE = {
      2 => /\A {2}/,
      4 => /\A {4}/,
      8 => /\A {8}/
    }

    def unindent(str, n)
      re = (INDENT_RE[n] ||= /\A {#{n}}/)
      str.sub(re, '')
    end

    #
    # inline
    #

    WikiName = /\b(?:[A-Z][a-z0-9]+){2,}\b/n
    BracketLink = /\[\[[!-~]+?\]\]/n
    SeemsURL = URI.regexp(%w{http ftp})
    NeedESC = /[&"<>]/

    def text(str)
      esctable = TextUtils::ESC
      str.gsub(/(#{NeedESC})|(#{WikiName})|(#{BracketLink})|(#{SeemsURL})/on) do
        if    ch  = $1 then esctable[ch]
        elsif tok = $2 then internal_link(tok)
        elsif tok = $3 then bracket_link(tok[2..-3])
        elsif tok = $4 then seems_url(tok)
        else
          raise 'must not happen...'
        end
      end
    end

    def internal_link(name)
      return escape_html(name) if name == @page_name
      return escape_html(name) if @db.invalid?(name)
      if @db.exist?(name)
      then %Q[<a href="#{view_url(name)}">#{escape_html(name)}</a>]
      else %Q[<a href="#{edit_url(name)}">#{escape_html(name)}</a>]
      end
      #%Q[<a href="#{view_url(name)}">#{escape_html(name)}</a>]
    end

    def view_url(page_name)
      if @config.html_url?
        "#{cgi_href}/#{escape_html(page_name)}#{@config.document_suffix}"
      else
        "#{cgi_href}?cmd=view&name=#{escape_url(page_name)}"
      end
    end

    def edit_url(page_name)
      "#{cgi_href}?cmd=edit&name=#{escape_url(page_name)}"
    end
    
    def cgi_href
      escape_html(@config.cgi_url)
    end

    # [[#abc:de]] -> #abc:de -> abc:de    send inline_ext__name(args)
    # [[img:http://xxxx]] or [[img:xxxx]]
    # [[http://xxx]]
    # [[WikiName]]
    def bracket_link(link)
      case link
      when /\A#/
        str = $'
        name, args = str.split(/:/,2)
        mid = "inline_ext__#{name}"
        return "[#{escape_html(link)}" unless respond_to?(mid, true)
        send(name, args)        
      when /\Aimg:/
        image_link = $'
        if SeemsURL =~ image_link and seems_image_url(image_link)
          %Q[<img src="#{escape_html(image_link)}">]
        elsif /\A[\w\-]+:/n =~ image_link
          # * ruby-list:http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/%s
          id, vary = image_link.split(/:/, 2)
          href = resolve_interwikiname(id, vary)
          if href and seems_image_url(href)
          then %Q[<img src="#{escape_html(href)}">]
          else "[#{escape_html(image_link)}]"
          end
        else "[#{escape_html(image_link)}]"
        end
      when SeemsURL   then %Q[<a href="#{escape_html(link)}">#{escape_html(link)}</a>]
      when /\A\w+\z/n then internal_link(link)
      else escape_html(link)
      end
    end

    def seems_url(url)
      if url[-1,1] == ')' and not paren_balanced?(url)
        url = url.chop
        %Q[<a href="#{escape_html(url)}">#{escape_html(url)}</a>)]
      else
        %Q[<a href="#{escape_html(url)}">#{escape_html(url)}</a>]
      end
    end

    def paren_balanced?(str)
      str.count('(') == str.count(')')
    end

    def seems_image_url(url)
      /\.(png|jpg|jpeg|bmp|gif|tiff|tif)\z/i =~ url
    end

    def resolve_interwikiname(name, vary)
      table = interwikiname_table or return nil
      return nil unless table.key?(name)
      sprintf(table[name], vary)
    end

    InterWikiName_LIST_PAGE = 'InterWikiName'

    def interwikiname_table
      @interwikinames ||= read_interwikiname_table(InterWikiName_LIST_PAGE)
    end

    def read_interwikiname_table(page_name)
      return nil unless @db.exist?(page_name)
      table = {}
      page = @db.find(page_name).source
      page.split(/\n/).each do |line|
        if /\A\s*\*\s*(\S+?):/ =~ line
          interwikiname = $1.strip
          url = $'.strip
          table[interwikiname] = url
        end
      end
      table
    end

    #
    # IO
    #
    class LineInput
      def initialize(f)
        @f = f
        @buf = []
      end

      def peek
        line = gets
        @buf.push line if line
        line
      end

      def gets
        return nil unless @buf
        return @buf.pop unless @buf.empty?

        line = @f.gets
        unless line
          @buf = nil
          return nil
        end
        line.rstrip
      end

      def ungets(line)
        @buf.push line
      end

      def next?
        peek() ? true : false
      end

      def while_match(re)
        while line = gets()
          unless re =~ line
            ungets line
            return
          end
          yield line
        end
        nil
      end

      def until_match(re)
        while line = gets()
          if re =~ line
            ungets line
            return
          end
          yield line
        end
        nil
      end

      def until_terminator(re)
        while (line = gets())
          return if re =~ line
          yield line
        end
        nil
      end

    end
  end
end

