#----------------------------------------------------------------
# entry
#----------------------------------------------------------------
module MyGhBlog
  class Entry
    def initialize(f=nil)
      @path_text = f
      ih.each{|k,v| instance_variable_set("@#{k}".to_sym, v)}
      ic.each{|k,v| instance_variable_set("@#{k}".to_sym, v)}
    end
    def detail
      instance_variables.each{|i|
        next if i == :@content
        next unless ih.has_key?(i.to_s.gsub("@",'').to_sym)
        next unless v = instance_variable_get(i)
        print i, ":\s\t", v.to_s, "\n"
      }
    end
    def update_page_index
      PageIndex.new.base
    end
    def to_str
      EntryTextData.new(ih, self).to_s
    end
    def to_xml
      return nil unless @uri
      return nil unless @uri_rel
      PageEntry.new().entry_page(self)
    end
    def hash_category
      return nil if @category.empty?
      h = Hash.new
      @category.split(',').map{|x|
        next unless x.ascii_only?
        x = x.strip
        next if x.empty?
        y = x.downcase
        next if /\W|[0-9]|import|test|^x$/.match(y)
        x = x.capitalize unless x[0].match(/[A-Z]/)
        h[x] = y
      }
      return nil if h.size == 0
      return h
    end
    private
    def check_error
      msg = "Error: content is empty.\n#{@path_text}\n"
      (print msg; exit) if @content.empty?
    end
    def set_base_time
      @t = Time.parse(@published) if @published
      @t ||= Time.now
      @year, @month, @day = @t.strftime("%Y,%m,%d").split(',')
    end
    def set_pub_date
      @updated = Time.now.iso8601.to_s
      @published ||= @t.iso8601.to_s
    end
    def set_edit_id
      @edit_id ||= @t.hash.to_s[2..13]
    end
    def set_html_fname
      h = {"\s"=>'-','-'=>'-'}
      str = @title.downcase.gsub('_','-').gsub(/\W/,h)
      dir = File.join(@dir_blog, @year, @month)
      n = 0 unless Dir.exist?(dir)
      n = Dir.entries(dir).select{|f| /html$/.match(f)}.size if Dir.exist?(dir)
      @fn_num = "entry-#{n+1}.html"
      # entry number (Japanese title)
      return @fn = @fn_num if str.empty?
      # entry str
      @fn = "#{str}.html"
      # File exit?
      path_html = File.join(@dir_blog, @year, @month, @fn)
      if File.exist?(path_html)
       n = Dir.entries(dir).select{|f| /#{str}/.match(f)}.size
       @fn = "#{str}-#{n+1}.html"
      end
      return @fn
    end
    def set_uri
      @uri ||= File.join(@uri_blog, @year, @month, @fn)
    end
    def set_uri_rel
      @uri_rel = @uri.gsub("#{@hostname}",'.')
    end
    def set_path_html
      @path_html = File.join(@dir_blog, @year, @month, @fn)
    end
    def get_path_html
      return nil unless @uri
      @uri.gsub(hostname, publicdir)
    end
    def read_f
      m = IO.read(@path_text).split(/^--content\n/)
      meta, @content = m[0], m[1..m.size].join("").strip
      msg = "Error: Read file #{@path_text}\n"
      (print msg ; exit) unless @content
      a = meta.split(/^--/); a.delete("")
      a.each{|x| ins_set(x)}
      set_base_time
    end
    def ih
      {
        :edit_id=>nil,
        :published =>nil, :updated=>nil, :date=>nil,
        :control=>'yes', :category=>"",
        :title=>'Draft Title',
        :uri=>nil, :url=>nil,
        :content=>""
      }
    end
    def ic
      {
        :hostname=>hostname,
        :uri_blog=>uri_host_blog,
        :dir_blog=>dir_local_blog,
        :tpl=>tplhtml
      }
    end
    def ins_set(x)
      k, v = x.chomp.split("\n")
      return nil unless v
      return nil unless instance_variable_defined?("@#{k}".to_sym)
      instance_variable_set("@#{k}".to_sym, v)
    end
    def save
      File.open(@path, 'w'){|f| f.print @data.to_s}
      print "saved: #{@path}\n"
    end
    def check_mkdir
      d = File.dirname(@path)
      return true if File.exist?(d)
      return makedir(d) unless File.exist?(d)
    end
    def makedir(d)
      return true if Dir.exist?(d)
      begin
        Dir.mkdir(d)
        print "maked directory: #{d}\n"
        return true
      rescue =>err
        puts err
        return false
      end
    end
    def save_text
      @path, @data = @path_text, to_str
      return false unless check_mkdir
      save
      return true
    end
    def save_html
      return nil unless @path_html
      @path, @data = @path_html, to_xml
      d = @dir_blog
      @path.gsub(@dir_blog,'').split('/').each{|x|
        d = File.join(d, x)
        next if d == @path
        next if d == @dir_blog+"/"
        unless makedir(d)
          print "Error: ENOENT #{d}\n"
          return false
        end
      }
      save
      return true
    end
  end
  class Draft < Entry
    def newentry
      if @path_text
        read_f
        @content = IO.read(@path_text) if @content.empty?
      end
      set_pubdata
      set_path_text
      save_text
    end
    private
    def set_pubdata
      @t = Time.now
      @year, @month, @day = @t.strftime("%Y,%m,%d").split(',')
      @date = @t.strftime("%Y/%m/%d %a %p %H:%M:%S")
    end
    def set_path_text
      str = @t.strftime("%Y-%m-%dT%H-%M-%S")
      @path_text = File.join(draftdir, "#{@year}-#{@month}", "#{str}.txt")
    end
  end
  class ViewEntry < Entry
    attr_reader  :path_html, :title, :published, :content, :category, :uri, :uri_rel, :posted, :edited
    def base
      read_f
    end
    def line_view
      t = Time.parse(@published) if @published
      t ||= Time.parse(@date.gsub(/AM|PM/,''))
      d = t.strftime("%Y/%m/%d %a %p %H:%M:%S")
      set_view_status
      title = set_view_title
      ary = [@posted, @edited, d, title, @category]
      printf "\t[%s]\s[%-s]\s[%-16s]\s[%s]\s(%s)\n" % ary
    end
    def set_view_title
      @title.gsub('_','-').gsub(/%|^/,'')
    end
    def set_view_status
      # posted?
      (@uri.nil?) ? @posted = '-' : @posted = '+'
      # updated?
      mt, ut  = File.mtime(@path_text), Time.parse(@updated.to_s) if @updated
      # when x is '-', entry need to update.
      (mt == ut) ? x = '+' : x = '-'
      # edited? # edited file after posted.  entry is '-'
      (x == '+' && @posted == '+') ? @edited = '+' :  @edited = '-'
      return [@posted, @edited]
    end
    def view_xhtml
      @path_html = get_path_html
      if @edited == '-'
        draft_view_xhtml unless @uri
        set_uri_rel if @uri
        return print to_xml
      elsif @edited == '+'
        return print IO.read(@path_html)
      end
    end
    def draft_view_xhtml
        set_base_time
        set_pub_date
        set_html_fname
        set_uri
        set_uri_rel
    end
    def view_detail
      @path_html = get_path_html
      detail
    end
  end
  class DeleteEntry < Entry
    def base
      read_f
      remove(@path_text)
      path_html = get_path_html
      return nil unless path_html
      return nil unless File.exist?(path_html)
      remove(path_html)
    end
    def remove(path)
      return nil unless path
      trash = trashdir
      return nil unless trash
      return nil unless File.exist?(trash)
      n = File.basename(path)
      new_path = File.join(trash, n)
      File.rename(path, new_path)
      print "\nFile:#{path}\nmove to\n=>#{new_path}\n"
    end
  end
  class PublicEntry < Entry
    # For PageIndex
    attr_reader :path_html, :title, :published, :uri_rel,
      :content, :category, :uri
    def base
      read_f
      set_uri_rel
      @path_html = get_path_html
      return self
    end
  end
  class PostEntry < Entry
    attr_reader :title, :published, :uri_rel, :content, :category
    def post
      base
      exit unless save_html
      exit unless save_text
    end
    private
    def base
      read_f
      check_error
      set_base_time
      set_pub_date
      set_edit_id
      set_html_fname
      set_path_html
      set_uri
      set_uri_rel
      # 
      set_control
      set_path_text
    end
    def set_control
      @control = @hostname if @control == 'yes'
    end
    def set_path_text
      str = @t.strftime("%Y-%m-%dT%H-%M-%S")
      @path_text = File.join(postdir, "#{@year}-#{@month}", "#{str}.txt")
    end
  end
  class UpdateEntry < PostEntry
    def update
      base
      exit unless save_html
      exit unless save_text
    end
    private
    def base
      read_f
      check_error
      return nil unless @path_html = get_path_html
      return print "Not Exist #{@path_html}\n" unless File.exist?(@path_html)
      @updated = Time.now.iso8601.to_s
      set_uri_rel
    end
  end
  class EntryTextData
    def initialize(inskeys, e)
      @str = String.new
      @e, @inskeys = e, inskeys
    end
    def to_s
      @inskeys.each{|k,v|
        i = "@#{k}".to_sym
        next unless @e.instance_variable_defined?(i)
        v = @e.instance_variable_get(i)
        @str << "--#{k}\n#{v}\n" unless v.nil?
      }
      return @str
    end
  end
  #end of module
end

