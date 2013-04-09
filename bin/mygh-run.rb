#!/path/to/ruby
# coding: utf-8
#---------------------------------------------------------------------
# mygh-run.rb
# ruby 1.9.3p327 (2012-11-10 revision 37606) [x86_64-darwin12.2.0]
#---------------------------------------------------------------------
module MyGhBlog
  class LoadConf
    def initialize
      conf_path = "/path/to/mygh-conf"
      unless File.exist?(conf_path)
        print "Error: Not exist mygh-conf\n"; exit
      end
      load(conf_path)
    end
  end
  class Start
    def initialize
      if RUBY_VERSION < "1.9"
        print "Error: Ruby Version\n";exit
      end
      unless Encoding.default_external.name == 'UTF-8'
        print "Error, LANG of default_external\n"; exit
      end
    end
    def run
      ARGV.empty? ? exit : ARGV.delete("")
      info
      require 'myghblog/arg'
      err, arg_h = CheckArg.new(ARGV).base
      exit if err == 'help'
      (print "#{err}\n"; exit) if err
      # Cheking Conf file
      LoadConf.new()
      CheckConf.send(:include, $MYGHBLOG)
      exit unless CheckConf.new().base
      Cmd.new(arg_h)
    end
    def info
      puts "#{'**'*20}\n run: #{Time.now.to_s}\n#{'**'*20}\n"
    end
  end
  class Cmd
    def initialize(h)
      require 'myghblog'
      @h, @f = h, nil
      comm
    end
    private
    def comm
      case @h.keys.join(",").to_s
      when /l/
        call_class_view
      when /draft/
        call_class_draft
      when /index/
        call_class_index
      when /page/
        call_class_page
      end
    end
    def call_class_view
      Entry.send(:include, $MYGHBLOG)
      Page.send(:include, $MYGHBLOG)
      str = @h[:l]
      View.new().base if str.nil?
      return unless /post|draft/.match(str)
      View.new(str).base
    end
    def call_class_draft
      f = opt = @h[:draft]
      Draft.send(:include, $MYGHBLOG)
      case opt
      when /.txt/
        exit unless File.exist?(f)
        Draft.new(f).newentry
      when 'new'
        Draft.new().newentry
      else
        Draft.new().newentry
      end
    end
    def call_class_page
      str = @h[:page]
      Entry.send(:include, $MYGHBLOG)
      Page.send(:include, $MYGHBLOG)
      case str
      when 'word'
        IndexAll.new.page_word
      when 'year'
        IndexAll.new.page_year
      when 'all'
      end
    end
    def call_class_index
      opt = @h[:index]
      Entry.send(:include, $MYGHBLOG)
      Page.send(:include, $MYGHBLOG)
      case opt
      when 'blog'
        IndexAll.new.index_blog
      when 'year'
        IndexAll.new.index_year
      when 'word'
        IndexAll.new.index_word
      when 'all'
        IndexAll.new.all
      end
    end
  end
  class CheckConf
    def initialize
      @err = String.new
      @hostname = hostname
      @datad = datadir
      @pubd = publicdir
      @tpl = tpldir
      #
      @draft = draftdir
      @post = postdir
      @trash = trashdir
      @tplh = tplhtml
      @dlocab = dir_local_blog
      @dar = dir_archive
      @dca = dir_category
    end
    def base
      instance_variables.each{|x|
        next if /err|hostname/.match(x)
        d = instance_variable_get(x)
        unless File.exist?(d)
          @err << "Error: Not exist #{d}\n"
        end
      }
      @err << "Error: 'def hostname' of Conf file\n" unless @hostname
      if @err.empty?
        return true
      elsif @err
        print @err; return false
      end
    end
  end
  #end of module
end

MyGhBlog::Start.new().run

