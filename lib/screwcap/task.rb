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

    validate(opts[:deployment_servers]) unless opts[:validate] == false or opts[:local] == true
  end

  # Run a command.  This can either be a string, or a symbol that is the name of a command set to run.
  #
  #
  #     command_set :list_of_tasks do
  #       run "do_this"
  #       run "do_that"
  #     end
  #  
  #     task_for :item, :servers => :server do
  #      run "ls -l"
  #      list_of_tasks
  #     end 
  #
  # Run also takes a list of *options*, notably :onfailure.  If :onfailure is given, and the command specified by run 
  # returns a non-zero status, screwcap will then abort the task and run the command set specified by :onfailure.
  #
  #
  #   command_set :rollback do
  #     run "rollback_this"
  #     run "rollback_that"
  #   end
  #
  #   task_for :item, :servers => :server do
  #    run "ls -l", :onfailure => :rollback
  #   end 
  def run arg, options = {}
    if arg.class == Symbol
      self.__commands << options.merge({:command => self.send(arg), :type => :remote, :from => self.__name})
    else
      self.__commands << options.merge({:command => arg, :type => :remote, :from => self.__name})
    end
  end

  # SCP a file from your local drive to a remote machine.
  #   task_for :item, :servers => :server do
  #     scp :local => "/tmp/pirate_booty", :remote => "/mnt/app/config/booty.yml"
  #   end 
  def scp options = {}
    self.__commands << options.merge({:type => :scp})
  end

  # Run a command locally.  This can either be a string, or a symbol that is the name of a command set to run.
  #
  #     task_for :item, :servers => :server do
  #      local "prepare_the_cats"
  #     end 
  #
  # local also takes a hash of *options*, notably :onfailure.  If :onfailure is given, and the command specified by run 
  # returns a non-zero status, screwcap will then abort the task and run the command set specified by :onfailure.
  #
  #   command_set :rollback do
  #     run "rollback_this"
  #   end
  #
  #   task_for :item, :servers => :server do
  #    local "herd_cats", :onfailure => :rollback
  #   end 
  def local arg, options = {}
    if arg.class == Symbol
      self.__commands << options.merge({:command => self.send(arg), :type => :local, :from => self.__name})
    else
      self.__commands << options.merge({:command => arg, :type => :local, :from => self.__name})
    end
    if failure_cmd = self.__commands.last[:onfailure]
      unless self.__command_sets.find {|cs| cs.__name == failure_cmd }
        raise ScrewCap::ConfigurationError, "Could not find failure command set named '#{failure_cmd}' for task '#{self.__name}'"
      end
    end
  end

  # not yet
  #def ask question, options = {}
  #  # if we are asking for user input, the task cannot be run in parallel.
  #  self.__options[:parallel] = false
  #  self.__commands << options.merge({:command => question, :type => :ask, :from => self.__name})
  #end

  #def prompt question, options = {}
  #  # if we are asking for user input, the task cannot be run in parallel.
  #  self.__options[:parallel] = false
  #  self.__commands << options.merge({:command => question, :type => :prompt, :from => self.__name})
  #end


  def __commands_for(name)
    cs = self.__command_sets.find {|cs| cs.__name == name}
    clone_table_for(cs)
    cs.instance_eval(&cs.__block)
    cs.__commands
  end

  protected

  def method_missing(m, *args) # :nodoc
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
    raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." if self.__server_names.nil? or self.__server_names == []

    self.__server_names.each do |server_name|
      raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." unless servers.map(&:name).include?(server_name)
    end

    # finally map the actual server objects via name
    self.__servers = self.__server_names.map {|name| servers.find {|s| s.name == name } }
  end

end
