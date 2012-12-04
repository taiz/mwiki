    #
    # Indent
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

    def indent_deeper?(line)
      indentof(line) > current_indent()
    end

    def indent_shallower?(line)
      indentof(line) < current_indent()
    end

    def indentof(line)
      detab(line.slice(/\A\s*/)).length
    end

    INDENT_RE = {
      2 => /\A {2}/,
      4 => /\A {4}/,
      8 => /\A {8}/
    }

    def unindent(line, n)
      re = (INDENT_RE[n] ||= /\A {#{n}}/)
      line.sub(re, '')
    end


      def inspect
        "\#<#{self.class} file=#{@f.inspect} line=#{lineno()}>"
      end

      def lineno
        @f.lineno
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

      def peek
        line = gets()
        ungets line if line
        line
      end

      def ungets(line)
        @buf.push line
      end

      def next?
        peek() ? true : false
      end

      def skip_blank_lines
        n = 0
        while line = gets()
          unless line.strip.empty?
            ungets line
            return n
          end
          n += 1
        end
        n
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
        while line = gets()
          return if re =~ line   # discard terminal line
          yield line
        end
        nil
      end
    end

  end

