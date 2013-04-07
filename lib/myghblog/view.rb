#----------------------------------------------------------------
# view
#----------------------------------------------------------------
module MyGhBlog
  class View
    def initialize(opt=nil)
      en = Entry.new()
      @opt = opt
      @dir = en.draftdir unless opt
      @dir = en.draftdir if opt == 'draft'
      @dir = en.postdir if opt == 'post'
      @n = 1
      @no = nil
      @req = nil
      @ary = Array.new
      @h = Hash.new
    end
    def base
      line_header
      Find.find(@dir).entries.sort.reverse.each{|f|
        next unless File.file?(f)
        next unless /\d{4}-\d{2}-\d{2}T/.match(f)
        next unless File.extname(f) == '.txt'
        entry(f)
        @n += 1
        #break if @n > 10
      }
      return print "Not exist entry.\n" if @ary.size < 1
      @no = select_no
      @obj = @ary[@no-1]
      @req = select_req
      return nil if @req == false
      run_req
    end
    private
    def line_header
      print "\n# Directory: #{@dir}\n#{'-'*90}\n"
      ary = ["status", "\s","Publishd or Draft Date", "\s", "title", "category"]
      printf "\t%-8s|%2s%-26s|%10s%-18s (%8s)\n" % ary
      print "#{'-'*90}\n"
    end
    def entry(f)
      e = ViewEntry.new(f)
      e.base
      @ary.push(e)
      @h[@n] = [f, e]
      print @n
      e.line_view
    end
    def select_no
      return 1 if @ary.size == 1
      Select.new.base("Select NO", @n-1)
    end
    def select_req
      set_select_msg
      Select.new.base(@msg, false)
    end
    def set_select_msg
      if @obj.posted == '-'
        str = "\n# Draft Entry\n"
        return @msg = str + "Select Request [i/e/t/x/p/r/h]"
      else
        str = "\n# Posted Entry\n"
        @msg = str + "Select Request [i/e/t/x/r/h]"
      end
      if @obj.edited == '-'
        str = "# Need Update Entry\n"
        @msg = str + "Select Request [i/e/t/x/u/r/h]"
      end
    end
    def run_req
      @text_path = @h[@no][0]
      @obj = @ary[@no-1]
      case @req
      when 'i' then file_detail
      when 'r' then file_delete
      when 'e' then file_open
      when 'x' then file_doc
      when 't' then file_text
      when 'p' then file_post
      when 'u' then file_update
      when 'h' then help_view
      end
      exit
    end
    def help_view
      opt_a = {
        :i=>'detail of this entry',
        :r=>'remove file to trash',
        :e=>'edit text file with vim',
        :x=>'print (x)html source',
        :t=>'print text file',
        :p=>'post entry.',
        :u=>'update entry'
      }
      opt_a.each{|k,v|
        ary = ["-#{k}",v]
        printf "\s%-3s\t%-30s\n" % ary
      }
    end
    def file_detail
      @obj.detail
      return nil unless @obj.uri
    end
    def file_delete
      DeleteEntry.new(@text_path).base
    end
    def file_doc
      @obj.view_xhtml
    end
    def file_text
      print @obj.to_str
      print "\n\n#\s=>\s", @text_path, "\n"
    end
    def file_post
      e = PostEntry.new(@text_path)
      e.post
      file_delete
      #e.update_page_index
      #print "Posted Entry.\n\n"
    end
    def file_update
      e = UpdateEntry.new(@text_path)
      e.base
      #e.update_page_index
      #print "Updated Entry.\n\n"
    end
    def file_open
      begin
        system("open -a 'MacVim' #{@text_path}")
      rescue
        return nil
      end
    end
  end

  class Select
    def base(str, opt)
      return false unless $stdin.tty?
      begin
        print "#{str}:\n"
        ans = $stdin.gets.chomp
        exit if /^n$|^no$/.match(ans)
        exit if ans.empty?
        case opt
        when true   # yes or no
          m = /^y$|^yes$/.match(ans)
          exit unless m
          return true
        when false  # return alphabet
          exit if (/\d/.match(ans) or ans.size > 7)
          return ans
        else        # return number
          i_ans = ans.to_i
          exit unless ans
          exit if (i_ans > opt or ans =~ /\D/)
          return i_ans
        end
      rescue SignalException
        exit
      end
    end
  end
  #end of module
end

