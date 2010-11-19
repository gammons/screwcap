class Task < Screwcap::Base
  include MessageLogger

  def initialize(opts = {}, &block)
    super
    self.__name = opts.delete(:name)
    self.__options = opts
    self.__commands = []
    self.__servers  = opts.delete(:servers)
    self.__block = block
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
    self.__commands << options.merge({:command => arg, :type => :remote, :from => self.__name})
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
    self.__commands << options.merge({:command => arg, :type => :local, :from => self.__name})
  end

  def __build_commands(command_sets = [])
    commands = []

    self.instance_eval(&self.__block)

    # :before for before_ callback
    if before = command_sets.find {|cs| cs.__name.to_s == "before_#{self.__name}" or cs.__name == self.__options[:before] } and before != self
      before.clone_from(self)
      commands << before.__build_commands(command_sets)
    end

    self.__commands.each do |command|
      if command[:type] == :unknown
        if cs = command_sets.find {|cs| cs.__name == command[:command] }
          cs.clone_from(self)
          commands << cs.__build_commands(command_sets)
        else
          raise(NoMethodError, "Cannot find task, command set, or other method named '#{command[:command]}'")
        end
      else
        commands << command
      end
    end

    # :after for after_ callback
    if after = command_sets.find {|cs| cs.__name.to_s == "after_#{self.__name}" or cs.__name == self.__options[:after] } and after != self
      after.clone_from(self)
      commands << after.__build_commands(command_sets)
    end

    commands.flatten
  end

  def validate(servers)
    raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." if servers == [] or servers.nil?

    # marshal :server into :servers
    self.__servers = [self.__options.delete(:server)] if self.__options[:server]
    self.__servers = [self.__servers] if self.__servers.class != Array

    server_names = servers.map {|s| s.__name }
    self.__servers.each do |server_name|
      raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." unless server_names.include?(server_name)
    end
  end

  private

  def method_missing(m, *args) # :nodoc
    if m.to_s[0..1] == "__" or [:run].include?(m) or m.to_s.reverse[0..0] == "="
      super(m, args.first) 
    else
      self.__commands << {:command => m, :type => :unknown, :from => self.__name}
    end
  end
end
