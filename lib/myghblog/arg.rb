#----------------------------------------------------------------
# arg
#----------------------------------------------------------------
module MyGhBlog
  class CheckArg
    def initialize(arg)
      begin
        @err, k, @h = false, nil, Hash.new
        arg.each{|x|
          m = /^-(.*)/.match(x)
          (m) ? (k = m[1].to_sym; @h[k] = nil) : @h[k] ||= x
        }
      rescue
        print "Error: see -h\n"; exit
      end
    end
    def base
      return help if (@h.has_key?(:h) or @h.has_key?(:help))
      return @err if check_opt
      return [@err, @h]
    end
    private
    def help
      arg_keys.each{|k,v|
        ary = ["-#{k}",v]
        printf "\s%-10s\t%-30s\n" % ary
      }
      @err = 'help'
      return [@err, nil]
    end
    def check_opt
      @h.keys.each{|k| @err = "Error: No option" unless arg_keys[k] }
      return @err
    end
    def arg_keys
      {
        :h=>"this help",
        :l=>"-l [ draft|post ]",
        :draft=>"-draft [ new|pathto/file ]",
        :index=>"-index [ blog|word|year ]",
        :page=>"-page [ word|year ]",
        :import=>"-import [pathto/dir]"
      }
    end
  end
end

