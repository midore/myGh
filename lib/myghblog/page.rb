#----------------------------------------------------------------
# page
#----------------------------------------------------------------
module MyGhBlog
  class Page
    attr_reader :dir, :doc, :div_e
    def initialize
      @n = 0
      @doc = REXML::Document.new(IO.read(tplhtml))
      @page_index = page_index
      @page_category = page_category
      @page_archive = page_archive
      @div_e = get_entries
      @dir = postdir
      @dir_ca = dir_category.gsub(publicdir, '.')
      @dir_ar = dir_archive.gsub(publicdir, '.')
      @yk, @ya = nil, Array.new
      @hash_word, @hash_wordindex, @hash_year = Hash.new, Hash.new, Hash.new
      @arr_entry = Array.new
    end
    def setup_category(title, h2)
      set_title(title)
      @div_e = set_div_category
      @div_e.add_element("h2").text=h2
      set_n
    end
    def setup_archives(title, h2)
      set_title(title)
      @div_e = set_div_archives
      @div_e.add_element("h2").text=h2
      set_n
    end
    private
    def set_n
      @div_e.add_text("\n")
    end
    def set_nn
      @div_e.add_text("\n\n")
    end
    def set_title(str)
      get_title.text = str
    end
    def set_base
      return nil if get_base.nil?
      return nil if get_base.attributes.empty?
      # base tag use <base href=xxxx /> of file "tpl.html".
      # stopping use "def tag_base" of file "mygh-conf"
      ##get_base.add_attributes({"href"=>tag_base})
    end
    def get_title
      @doc.elements['html/head/title']
    end
    def get_base
      @doc.elements['html/head/base']
    end
    def get_entries
      e = @doc.get_elements("html/body/div").select{|x|
         x.attributes["id"]== "entries"
      }[0]
      return e
    end
    def save
      File.open(@path, 'w'){|f| f.print @data.to_s}
      print "saved: #{@path}\n"
    end
    def entry_div(e)
      DivEntry.new(e, @dir_ca).doc
    end
    def set_div_archives
      e = get_entries
      e.delete_attribute("id")
      e.add_attributes({"id"=>"archives"})
      return e
    end
    def set_div_category
      e = get_entries
      e.delete_attribute("id")
      e.add_attributes({"id"=>"category"})
      return e
    end
    def new_plink(uri, str)
      ep = REXML::Element.new("p")
      ea = ep.add_element("a")
      ea.add_attributes("href"=>uri)
      ea.text = str
      return ep
    end
    def set_hash
      Find.find(@dir).entries.sort.reverse.each{|f|
        next unless File.file?(f)
        next unless /\d{4}-\d{2}-\d{2}T/.match(f)
        next unless File.extname(f) == '.txt'
        next unless File.exist?(PublicEntry.new(f).base.path_html)
        @arr_entry.push(f)
        set_arr_sub(f)
      }
    end
    def set_arr_sub(f)
      e = PublicEntry.new(f).base
      ep = LinkToEntry.new(e, @dir_ca).ep
      set_year_h(f, ep)
      h = e.hash_category
      return ep unless h
      h.each{|k,v|
        set_word_h(k, v, ep)
        set_wordindex_h(k,v)
      }
    end
    def set_wordindex_h(k,v)
      @hash_wordindex[k] ||= "#{@dir_ca}/#{v}.html"
    end
    def set_word_h(k, v, ep)
      @hash_word[k] = Array.new unless @hash_word[k]
      @hash_word[k].push(ep)
    end
    def set_year_h(f, ep)
      yk =  f.match(/\d{4}/)[0]
      unless @yk == yk
        @yk, @ya = yk, Array.new
      end
      @ya.push(ep)
      @hash_year[@yk] = @ya
    end
  end
  class PageEntry < Page
    def entry_page(e)
      set_title(e.title)
      set_nn
      @div_e.add_element(entry_div(e))
      set_nn
      return @doc
    end
  end
  class IndexAll < Page
    def all
      set_hash
      index_blog
      index_year
      index_word
      page_word
      page_year
    end
    def category
      set_hash
      index_word
      page_word
    end
    def archives
      set_hash
      index_year
      page_year
    end
    def index_blog
      set_hash if @arr_entry.empty?
      @path = @page_index
      set_title("Blog")
      n = 0
      @arr_entry.each{|f|
        e = PublicEntry.new(f).base
        @div_e.add_text("\n\n")
        @div_e.add_element(entry_div(e))
        n += 1
        break if n+1 > count_entry_index.to_i
      }
      @div_e.add_text("\n\n")
      @data = @doc
      save
    end
    def index_word
      set_hash if @hash_wordindex.empty?
      @doc = REXML::Document.new(IO.read(tplhtml))
      @path = @page_category
      setup_category("Category","Blog Category")
      @ep, @kw = nil, nil
      n = 0
      @hash_wordindex.sort.each{|k,v|
        unless @kw == k[0]
          @ep = REXML::Element.new("p").add_text("\s|\s")
          @div_e.add_element(@ep)
          set_n
          @kw = k[0]
          n += 1
        end
        set_index_category_ea(k, v)
        @ep.add_text("\s|\s")
      }
      @data = @doc
      save
    end
    def index_year
      set_hash if @hash_year.empty?
      @doc = REXML::Document.new(IO.read(tplhtml))
      @path = @page_archive
      setup_archives("Archives","Blog Archives")
      @hash_year.keys.each{|k|
        ep = set_index_year_ep(k)
        @div_e.add_text("\t")
        @div_e.add_element(ep)
      }
      @data = @doc
      save
    end
    def page_word
      set_hash if @hash_word.empty?
      @hash_word.each{|k,v|
        @path = File.join(dir_category, "#{k.downcase}.html")
        @page = Page.new
        @page.setup_category("BlogCategory", "Word: #{k}")
        v.each{|ep|
          @page.div_e.add_element(ep)
          @page.div_e.add_text("\n")
        }
        @data = @page.doc
        save
      }
    end
    def page_year
      set_hash if @hash_year.empty?
      @hash_year.each{|k,v|
        @path = File.join(dir_archive, "#{k}.html")
        @page = Page.new
        @page.setup_archives("BlogArchives","Year: #{k}")
        v.each{|x|
          @page.div_e.add_element(x)
          @page.div_e.add_text("\n")
        }
        @data = @page.doc
        save
      }
    end
    def set_index_year_ep(k)
      u = File.join(@dir_ar, "#{k}.html")
      new_plink(u, k.capitalize)
    end
    def set_index_category_ea(k, v)
      ea = @ep.add_element("a")
      ea.add_attributes("href"=>v)
      ea.text = k
      return ea
    end
  end
  class LinkToEntry
    attr_reader :ep
    def initialize(e, dir_ca)
      @dir_ca = dir_ca
      @pubd, @title, @uri_rel = e.published, e.title, e.uri_rel
      @h = e.hash_category
      @ep = REXML::Element.new("p")
      @deh = DivEntryHeader.new(e, @dir_ca)
      setup
    end
    private
    def setup
      ea = @ep.add_element("a")
      ea.add_attributes({"href"=>@uri_rel})
      ea.text = "#{Time.parse(@pubd).strftime("%Y-%m-%d")}\s|\s#{@title}"
      return nil unless @h
      link_category
    end
    def link_category
      @ep.add_text("\s(")
      @deh.setup_link(@ep)
      @ep.add_text("\s)")
    end
  end
  #end of module
end

