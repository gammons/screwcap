class Task < Screwcap::Base
  include MessageLogger

  def initialize(opts = {}, &block)
    super
    self.__name = opts.delete(:name)
    self.__options = opts
    self.__commands = []
    self.__local_before_command_sets = []
    self.__local_after_command_sets = []
    self.__servers  = opts.delete(:servers)
    self.__callback = opts.delete(:callback)
    self.__block = block

    if self.__options[:before] and self.__options[:before].class != Array
      self.__options[:before] = [self.__options[:before]] 
    end
    if self.__options[:after] and self.__options[:after].class != Array
      self.__options[:after] = [self.__options[:after]] 
    end
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

  # execute a ruby command.
  # command_set :test do
  #   run "do this"
  #   ex { @myvar = true }
  #   run "do that"
  # end
  #
  # this is good for calling an external service during your deployment.
  #
  # command_set :after_deploy do
  #   ex { $hipchat_client.send "Deployment has finished" }
  # end
  def ex(&block)
    self.__commands << {:type => :block, :from => self.__name, :block => block}
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
  end

  # For a task, declare a set of things to run before or after a command set. 
  #    command_set :release_the_hounds do
  #      run "release_the_hounds"
  #    end
  #
  #    task :release do
  #      before :release_the_hounds do
  #        run "unlock_the_gate"
  #      end
  #      after :release_the_hounds do
  #        run "find_and_gather_released_hounds"
  #      end
  #      release_the_hounds
  #    end

  def before name, &block
    self.__local_before_command_sets << Task.new(:name => name, :callback => true, &block)
  end

  # For a task, declare a set of things to run before or after a command set. 
  #    command_set :release_the_hounds do
  #      run "release_the_hounds"
  #    end
  #
  #    task :release do
  #      before :release_the_hounds do
  #        run "unlock_the_gate"
  #      end
  #      after :release_the_hounds do
  #        run "find_and_gather_released_hounds"
  #      end
  #      release_the_hounds
  #    end

  def after name, &block
    self.__local_after_command_sets << Task.new(:name => name, :callback => true, &block)
  end

  def __build_commands(command_sets = [], _self = self)
    commands = []

    self.__commands = []
    self.instance_eval(&self.__block)

    unless self.__callback == true
      if self.__options[:before]
        self.__options[:before].each do |before|
          before = command_sets.find {|cs| cs.__name.to_s == before.to_s}
          next if before.nil? or before == self
          before.clone_from(self)
          commands << before.__build_commands(command_sets)
        end
      end

      command_sets.select {|cs| cs.__name.to_s == "before_#{self.__name}"}.each do |before|
        next if before == self
        before.clone_from(self)
        commands << before.__build_commands(command_sets)
      end
    end

    self.__commands.each do |command|
      if command[:type] == :unknown
        if cs = command_sets.find {|cs| cs.__name == command[:command] }
          cs.clone_from(_self)

          _self.__local_before_command_sets.each do |lcs|
            if command[:command] == lcs.__name
              lcs.clone_from(_self)
              commands << lcs.__build_commands(command_sets, _self)
            end
          end

          commands << cs.__build_commands(command_sets, _self)

          _self.__local_after_command_sets.each do |lcs|
            if command[:command] == lcs.__name
              lcs.clone_from(_self)
              commands << lcs.__build_commands(command_sets, _self)
            end
          end

        else
          raise(NoMethodError, "Cannot find task, command set, or other method named '#{command[:command]}'")
        end
      else
        commands << command
      end
    end

    unless self.__callback == true
      if self.__options[:after]
        self.__options[:after].each do |after|
          after = command_sets.find {|cs| cs.__name.to_s == after.to_s}
          next if after.nil? or after == self
          after.clone_from(self)
          commands << after.__build_commands(command_sets)
        end
      end

      command_sets.select {|cs| cs.__name.to_s == "after_#{self.__name}"}.each do |after|
        next if after == self
        after.clone_from(self)
        commands << after.__build_commands(command_sets, self)
      end
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
    if m.to_s[0..1] == "__" or [:run, :ex].include?(m) or m.to_s.reverse[0..0] == "="
      super(m, args.first) 
    elsif m == :to_ary
      # In Ruby 1.9, Array#flatten calls #to_ary on each of the
      # array's children and only if there is a NoMethodError raised
      # does it assume the object is not an array. Compare this to
      # 1.8.7 where Array#flatten used #respond_to? to determine
      # if the object responded to #to_ary before calling it.
      #
      # Therefore we need to raise this error if someone calls #to_ary
      # on us
      raise NoMethodError
    else
      self.__commands << {:command => m, :type => :unknown, :from => self.__name}
    end
  end
end
