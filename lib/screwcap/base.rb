begin 
  require 'rubygems'
  gem 'net/ssh'
  gem 'mocha'
rescue  LoadError
end

class Screwcap
  class Base
    attr_accessor :options

    # the meat and potatoes.
    # getter / setter for any user definable option
    def method_missing(m, *args, &block)
      return @options[m.to_sym] = args.first if args and args.size == 1
      return @options[m.to_sym] = args if args and args != []
      @options[m.to_sym]
    end
  end


  class NoServersDefined < Exception; end
  class NoServerSelected < Exception; end
  class TaskNotFound < Exception; end
  class ConfigurationError < Exception; end
  class IncludeFileNotFound < Exception; end
  class InvalidServer < Exception; end
  class CommandSetDependencyError < Exception; end

end
