require 'cgi'

module MWiki

  module TextUtils

    def detab(str, ts = 8)
      add = 0
      str.gsub(/\t/) {
        len = ts - ($~.begin(0) + add) % ts
        add += len - 1
        ' ' * len
      }
    end

    def escape_html(str)
      CGI.escapeHTML(str)
    end

    ESC = {
      '&' => '&amp;',
      '"' => '&quot;',
      '<' => '&lt;',
      '>' => '&gt;'
    }

  end

end
