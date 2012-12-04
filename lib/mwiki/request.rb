require 'mwiki/textutils'

module MWiki

  class Request
    include TextUtils

    def initialize(request, locale)
      @request  = request
      @locale   = locale
    end

    def cmd
      cmd = get('cmd').to_s.downcase
      return nil unless cmd or page_name
      @cmd ||= cmd
    end

    # .htmlアクセスはviewに変換する
    def page_name
      name = get('name')
      return name if name

      html = @request.path.split("\/").last.strip
      return nil unless /\.html\z/i =~ html.downcase

      @cmd = 'view'
      html.gsub(/\.html/i,'')
    end

    def normalized_text
      text = get('text')
      return nil unless text
      normalize_text(text)
    end

    def preview?
      get('preview') ? true : false
    end

    def search_query
      get('q').to_s.strip
    end

    def search_regexps
      setup_query(search_query())
    end

    def setup_query(query)
      raise WrongQuery, 'no pattern' unless query
      patterns = query.split(/\s+/).map do |pat|
        check_pattern(pat)
        /#{Regexp.quote(pat)}/i
      end
      raise WrongQuery, 'no pattern' if patterns.empty?
      raise WrongQuery, 'too many sub patterns' if patterns.length > 8
      patterns
    end
    private :setup_query

    def check_pattern(pat)
      raise WrongQuery, 'no pattern' unless pat
      raise WrongQuery, 'empty pattern' if pat.empty?
      raise WrongQuery, "pattern too short: #{pat}" if pat.length < 1
      raise WrongQuery, 'pattern too long' if pat.length > 128
    end    
    private :check_pattern

    private

    def normalize_text(text)
      lines = text.split(/\n/).map do |line|
        l = line.chomp.rstrip + "\r\n"
        detab(l)
      end.join('')
    end

    # httpパラメータの抽出
    def get(name)
      data = @request.query[name]
      return nil unless data
      return nil if data.empty?
      data.to_s
    end

  end

end

