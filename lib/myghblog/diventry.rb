#----------------------------------------------------------------
# diventry
#----------------------------------------------------------------
module MyGhBlog
  class DivEntry
    attr_reader :doc
    def initialize(e, dir_ca)
      @e = e
      @dir_ca = dir_ca
      ev = DivEntryHeader.new(@e, @dir_ca)
      @eleroot, @elehead, @ele = ev.eleroot, ev.elehead, ev.ele
      @doc = DivEntryContent.new(@e, @eleroot, @ele).base
    end
  end
  class DivEntryHeader
    attr_accessor :eleroot, :elehead, :ele
    def initialize(e, dir_ca)
      @e = e
      @dir_ca = dir_ca
      @ary_category = set_ary_category
      div1 = REXML::Element.new("div")
      div1.add_text("\n")
      div1.add_attributes({"id"=>"entry"})
      #div1.add_text("\n")
      div2 = attrset(div1, "div", ["id","entry_header"])
      div1.add_text("\n")
      #div1.add_text("\n")
      div3 = attrset(div1, "div", ["id","entry_content"])
      #div1.add_text("\n")
      @eleroot, @elehead, @ele = div1, div2, div3
      setup_header
    end
    def set_ary_category
      return nil if @e.category.empty?
      a = @e.category.split(',').map{|x|
        next unless x.ascii_only?
        x = x.strip.downcase
        x unless /import|test|^x$/.match(x)
      }.compact
      return nil if a.size == 0
      return a
    end
    private
    def attrset(e, str, a)
      ae = e.add_element(str)
      ae.add_attributes({a[0]=>a[1]})
      return ae
    end
    def setup_header
      # entry_title
      h3 = attrset(@elehead,"h3",["class","entry_title"])
      a = attrset(h3, 'a', ['href',@e.uri_rel])
      a.text = @e.title
      # entry_published
      h3 = attrset(@elehead, "h3", ["class","entry_published"])
      h3.text = Time.parse(@e.published).strftime("%Y-%m-%d")
      # entry_category
      setup_category
    end
    def setup_category
      return nil unless @ary_category
      h3 = attrset(@elehead,"h3",["class","entry_category"])
      @n = 0
      @ary_category.each{|v|
        str = v.downcase
        h3.add_text("\s|\s") unless @n == 0
        a = attrset(h3, 'a', ['href', File.join(@dir_ca, "#{str}.html")])
        a.text = str.capitalize
        @n += 1
      }
    end
  end
  class DivEntryContent
    def initialize(e, eleroot, ele)
      @e = e
      @ary = @e.content.strip.lines.to_a
      @eleroot, @ele = eleroot, ele
      @tag, @mark = "default", 0
    end
    def base
      setup_content
      @ele.add_text("\n")
      @eleroot.add_text("\n")
      return @eleroot
    end
    private
    def setup_content
      @ary.each_with_index{|x,no| linetoxml(x,no)}
      tag_p(@ary.size+1) if @mark < @ary.size
    end
    def linetoxml(x, no)
      xs = x.strip
      case xs
      when /^<pre>$|^<blockquote>$/
        m = /\<(.*?)\>/.match(xs)
        @tag = m[1] if m
        tag_p(no) unless no == 0
        @mark = @mark+1 if no == 0
      when /^<\/pre>$|^<\/blockquote>$/
        tag_x(no)
      end
    end
    def tag_x(no)
      @ele.add_text("\n")
      w = @ary[@mark..no-1]
      e = @ele.add_element(@tag)
      case @tag
      when "pre"
        co = REXML::Element.new("code")
        w.each{|x| co.add_text(x)}
        e.add_element(co)
      when "blockquote"
        e.add_text("\n")
        ep = e.add_element("p")
        w.each_with_index{|line,n|
          ep.add_text(line.chomp)
          ep.add_element("br") unless n+1 == w.size
        }
      end
      @tag ,@mark = nil, no+1
    end
    def tag_p(no)
      @ele.add_text("\n")
      e = @ele.add_element("p")
      w = @ary[@mark..no-1]
      @wn = w.size
      #w.delete_at(0) if w[0] == "\n"
      #return e if w[0] == "\n"
      w.each_with_index{|line,n| sub_tag_p(line, n, e)}
      @mark = no+1
    end
    def sub_tag_p(line, n, e)
        if /<a(.*?)>(.*?)<\/a>/.match(line)
          tag_a(line, e)
          e.add_element("br") unless n+1 == @wn
        else
          e.add_text(line.chomp)
          e.add_element("br") unless n+1 == @wn
        end
    end
    def tag_a(line, e)
      m = /<a(.*?)>(.*?)<\/a>/.match(line)
      url, str = m[1].gsub(/href=|'|"|\s/,''), m[2].to_s
      pre, pos = m.pre_match, m.post_match
      e.add_text(pre) if pre
      e.add_element(sub_tag_a(url, str))
      e.add_text(pos) if pos
    end
    def sub_tag_a(url, str)
      ea = REXML::Element.new('a')
      ea.add_attributes({"href"=>url})
      ea.text = str
      return ea
    end
  end
  # end of module
end

