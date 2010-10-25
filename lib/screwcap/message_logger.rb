module MessageLogger
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def log(msg, options = {})
      logmsg(msg, $stdout, options)
    end

    def errorlog(msg, options = {})
      logmsg(msg, $stderr, options)
    end

    private

    def logmsg(msg, output, options)
      return if @options and @options[:silent] == true
      if @options and not @options[:nocolor] == true
        case options[:color]
        when :blue
          output << "\033[0;36m#{msg}#{"\033[0m" if options[:clear]}"
        when :bluebold
          output << "\033[1;36m#{msg}#{"\033[0m" if options[:clear]}"
        when :red
          output << "\033[0;31m#{msg}#{"\033[0m" if options[:clear]}"
        when :green
          output << "\033[0;32m#{msg}#{"\033[0m" if options[:clear]}"
        end
      else
        output << msg
      end
    end
  end
end
