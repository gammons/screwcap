class CommandSet < Screwcap::Base
  def initialize(opts = {}, &block)
    super(opts)
    self.__name = opts[:name]
    self.__options = opts
    self.__commands = []
    self.__command_sets = []
    self.__block = block
  end

  # run a command. basically just pass it a string containing the command you want to run.
  def run arg, options = {}
    if arg.class == Symbol
      self.__commands << self.send(arg)
    else
      self.__commands << arg
    end
  end

  def compile!
  end

  protected

  def method_missing(m, *args)
    if m.to_s[0..1] == "__" or [:run].include?(m) or m.to_s.reverse[0..0] == "="
      super(m, args.first) 
    else
      if self.__command_sets.map(&:name).include?(m)
        self.__commands += self.__command_sets.find {|cs| cs.name == m }.__commands
      else
        raise NoMethodError, "Undefined method '#{m.to_s}' for task :#{self.name.to_s}"
      end
    end
  end
end
