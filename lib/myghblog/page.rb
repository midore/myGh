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
      #@base = tag_base
      @yk, @ya = nil, Array.new
      @hash_word, @hash_wordindex, @hash_year = Hash.new, Hash.new, Hash.new
      @arr_entry = Array.new
      set_base
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
    def set_title(str)
      get_title.text = str
    end
    def set_base
      return nil unless @base
      get_base.add_attributes({"href"=>@base})
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
      @arr_entry = Array.new
      Find.find(@dir).entries.sort.reverse.each{|f|
        next unless File.file?(f)
        next unless /\d{4}-\d{2}-\d{2}T/.match(f)
        next unless File.extname(f) == '.txt'
        e = PublicEntry.new(f).base
        next unless File.exist?(e.path_html)
        @arr_entry.push(e)
        set_arr_sub(e, f)
      }
    end
    def set_arr_sub(e, f)
      link = LinkToEntry.new(e, @dir_ca)
      ep = link.ep
      set_year_h(f, ep)
      return ep unless link.ary
      link.ary.each{|k|
        set_word_h(k, ep)
        set_wordindex_h(k)
      }
    end
    def set_wordindex_h(k)
      @hash_wordindex[k] ||= "#{@dir_ca}/#{k}.html"
    end
    def set_word_h(k, ep)
      @hash_word[k] = Array.new unless @hash_word[k]
      @hash_word[k].push(ep)
    end
    def set_year_h(f, x)
      yk =  f.match(/\d{4}-\d{2}/)[0]
      yk =  f.match(/\d{4}/)[0]
      unless @yk == yk
        @yk, @ya = yk, Array.new
      end
      @ya.push(x)
      @hash_year[@yk] = @ya
    end
  end
  class PageEntry < Page
    def entry_page(e)
      set_title(e.title)
      @div_e.add_element(entry_div(e))
      return @doc
    end
  end
  class PageIndex < Page
    def base
      @path = @page_index
      set_title("Blog")
      set_hash
      @data = data_index_page
      @n = 0
      save
    end
    private
    def data_index_page
      @arr_entry.each{|e|
        @div_e.add_text("\n\n")
        @div_e.add_element(entry_div(e))
        @div_e.add_text("\n\n")
        @n += 1
        break if @n+1 > count_entry_index.to_i
      }
      return @doc
    end
  end
  class CategoryIndex < Page
    def base
      @path = @page_category
      setup_category("Category","Blog Category")
      set_hash
      @data = data_category_index
      save
    end
    private
    def data_category_index
      @ep, @kw = nil, nil
      @hash_wordindex.sort.each{|k,v|
        kw = k[0]
        unless @kw == kw
          if @ep
            @div_e.add_text("\t")
            @div_e.add_element(@ep)
            @div_e.add_text("\n\t")
          end
          @ep = set_index_ep
          @kw = kw
        end
        set_index_ea(k, v)
        @ep.add_text("\s|\s")
      }
      @div_e.add_element(@ep)
      @div_e.add_text("\n\t")
      return @doc
    end
    def set_index_ep
      ep = REXML::Element.new("p")
      ep.add_text("\s|\s")
      return ep
    end
    def set_index_ea(k, v)
      ea = @ep.add_element("a")
      ea.add_attributes("href"=>v)
      ea.text = "#{k.capitalize}"
      return ea
    end
  end
  class ArchivesIndex < Page
    def base
      @path = @page_archive
      setup_archives("Archives","Blog Archives")
      set_hash
      @data = data_archives_index
      save
    end
    private
    def data_archives_index
      @hash_year.keys.each{|k|
        ep = set_year_index_ep(k)
        @div_e.add_text("\t")
        @div_e.add_element(ep)
      }
      return @doc
    end
    def set_year_index_ep(k)
      u = File.join(@dir_ar, "#{k}.html")
      new_plink(u, k.capitalize)
    end
  end
  class Category < Page
    def base
      set_hash
      @hash_word.each{|k,v| data_category(k, v)}
    end
    private
    def data_category(k, v)
      @path = File.join(dir_category, "#{k}.html")
      @page = Page.new
      @page.setup_category("#{k.capitalize}", "Word: #{k.capitalize}")
      v.each{|x|
        @page.div_e.add_element(x)
        @page.div_e.add_text("\n")
      }
      @data = @page.doc
      save
    end
  end
  class Archives < Page
    def base
      set_hash
      @hash_year.each{|k,v| data_archive(k, v)}
    end
    private
    def data_archive(k, v)
      @path = File.join(dir_archive, "#{k}.html")
      @page = Page.new
      @page.setup_archives("BlogArchives","Year: #{k}")
      v.each{|x|
        @page.div_e.add_element(x)
        @page.div_e.add_text("\n")
      }
      @data = @page.doc
      save
    end
  end
  class LinkToEntry
    attr_reader :ep, :ary
    def initialize(e, dir_ca)
      @e = e
      @dir_ca = dir_ca
      @ary = DivEntryHeader.new(@e, @dir_ca).set_ary_category
      @hn = e.hostname
      @pubd, @uri, @title = @e.published, @e.uri, @e.title
      @ep = REXML::Element.new("p")
      @ea = @ep.add_element("a")
      setup
    end
    private
    def setup
      @ea.add_attributes({"href"=>@e.uri_rel})
      @ea.text = "#{Time.parse(@pubd).strftime("%Y-%m-%d")}\s|\s#{@title}"
      return nil unless @ary
      link_category
    end
    def link_category
      @ep.add_text("\s(")
      @ary.each_with_index{|x,n|
        @ep.add_text("\s,\s") unless n == 0
        ea = @ep.add_element("a")
        url = File.join(@dir_ca, "#{x}.html")
        ea.add_attributes({"href"=>url})
        ea.text = x.capitalize
      }
      @ep.add_text(")")
    end
  end
  #end of module
end

