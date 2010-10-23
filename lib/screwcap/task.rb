class Task < Screwcap::Base
  include MessageLogger

  def initialize(opts = {}, &block)
    super
    self.__name = opts[:name]
    self.__options = opts
    self.__commands = []
    self.__command_sets = opts[:command_sets] || []
    self.__server_names = []
    self.__block = block if opts[:command_set] == true


    if opts[:server] and opts[:servers].nil?
      self.__server_names << opts[:server]
    else
      self.__server_names = opts[:servers]
    end

    validate(opts[:deployment_servers]) unless opts[:validate] == false
  end

  # run a command. basically just pass it a string containing the command you want to run.
  def run arg, options = {}

    if arg.class == Symbol
      self.__commands << {:command => self.send(arg), :type => :remote}
    else
      self.__commands << {:command => arg, :type => :remote}
    end
  end

  def scp options = {}
    self.__commands << options.merge({:type => :scp})
  end

  # run a command. basically just pass it a string containing the command you want to run.
  def local arg, options = {}
    if arg.class == Symbol
      self.__commands << {:command => self.send(arg), :type => :local}
    else
      self.__commands << {:command => arg, :type => :local}
    end
  end

  protected

  def method_missing(m, *args)
    if m.to_s[0..1] == "__" or [:run].include?(m) or m.to_s.reverse[0..0] == "="
      super(m, args.first) 
    else
      if cs = self.__command_sets.find {|cs| cs.__name == m }
        # eval what is in the block
        clone_table_for(cs)
        cs.__commands = []
        cs.instance_eval(&cs.__block)
        self.__commands += cs.__commands
      else
        raise NoMethodError, "Undefined method '#{m.to_s}' for task :#{self.name.to_s}"
      end
    end
  end

  private

  def clone_table_for(object)
    self.table.each do |k,v|
      object.set(k, v) unless [:__block, :__tasks, :__name, :__command_sets, :__commands, :__options].include?(k)
    end
  end

  def validate(servers)
    raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." if self.__server_names.blank?

    self.__server_names.each do |server_name|
      raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." unless servers.map(&:name).include?(server_name)
    end

    # finally map the actual server objects via name
    self.__servers = self.__server_names.map {|name| servers.find {|s| s.name == name } }
  end

end
