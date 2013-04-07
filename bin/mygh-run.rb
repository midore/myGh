#!usr/bin/ruby
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
        print "Error: Not exist conf file path\n"
        exit
      end
      load(conf_path)
    end
  end
  class Start
    def initialize
      #dir = File.dirname(File.dirname(File.expand_path($PROGRAM_NAME)))
      #$LOAD_PATH.push(File.join(dir, 'lib'))
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
      when /import/
        call_class_import
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
        Category.new.base
      when 'year'
        Archives.new.base
      when 'all'
        Archives.new.base
        Category.new.base
      end
    end
    def call_class_index
      opt = @h[:index]
      Entry.send(:include, $MYGHBLOG)
      Page.send(:include, $MYGHBLOG)
      case opt
      when 'blog'
        PageIndex.new.base
      when 'year'
        ArchivesIndex.new.base
      when 'word'
        CategoryIndex.new.base
      when 'all'
        PageIndex.new.base
        ArchivesIndex.new.base
        CategoryIndex.new.base
      end
    end
    def call_class_import
      d = @h[:import]
      return nil unless d
      return nil unless Dir.exist?(d)
      Entry.send(:include, $MYGHBLOG)
      Page.send(:include, $MYGHBLOG)
      Import.new(d)
    end
  end
  class CheckConf
    def initialize
      @err  = String.new
      @hostname = hostname
      @datad  = datadir
      @pubd = publicdir
      @tpl = tpldir
      #
      @draft = draftdir
      @post = postdir
      @trash = trashdir
      @tplh = tplhtml
      @dlocab = dir_local_blog
      @dar =  dir_archive
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

