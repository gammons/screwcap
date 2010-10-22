module Screwcap
  class Base < OpenStruct

    # for debugging purposes only
    #def method_missing(m, *args, &block)
    #  $stdout << "For #{self.class.to_s}: calling #{m}\n"
    #  super(m, args.first)
    #end

    def set(var, *args)
      method_missing((var.to_s + "=").to_sym, args.first)
    end

    def log(msg, options = {})
      $stdout << msg unless self.__options[:silent] == true
    end

    def errorlog(msg)
      $stderr << msg unless self.__options[:silent] == true
    end

    def bluebold(msg, options = {:clear => true})
      if self.__options[:nocolor] == true
        msg
      else
        "\033[1;36m#{msg}#{"\033[0m" if options[:clear]}"
      end
    end

    def blue(msg, options = {:clear => true})
      if self.__options[:nocolor] == true
        msg
      else
        "\033[0;36m#{msg}#{"\033[0m" if options[:clear]}"
      end
    end


    def red(msg)
      if self.__options[:nocolor] == true
        msg
      else
        "\033[0;31m#{msg}\033[0m"
      end
    end

    def green(msg)
      if self.__options[:nocolor] == true
        msg
      else
        "\033[0;32m#{msg}\033[0m"
      end
    end

  end
end
