# The deployer is the class that holds the overall params from the screwcap tasks file, and it is also in charge of running the requested task.
#
# The deployer can be thought of as the "global scope" of your tasks file.
class Deployer < Screwcap::Base
    attr_accessor :tasks, :default_svn, :default_deploy, :default_mongrel, :debug, :args
  
    # create a new deployer.
    def initialize(task_to_run, options = {})
      raise Screwcap::TaskNotFound, "Please specify a task to run." if task_to_run.nil?

      @options = {:tasks => [], :command_sets => [], :task_to_run => task_to_run.to_sym, :task_file => File.expand_path("./config/screwcap_tasks.rb"), :from_rake => true}.merge(options)

      $stdout << "Attempting to read #{@options[:task_file]}\n" unless options[:silence] == true
      file = File.open(File.expand_path("./#{@options[:task_file]}"))
      data = file.read

      instance_eval(data)
    end

    def run!
      raise Screwcap::TaskNotFound, "Could not Find task named #{@options[:task_to_run]} in #{@options[:task_file]}!" if not @options[:tasks].any? {|r| r.name == @options[:task_to_run]}
      @options[:tasks].select {|r| r.name == @options[:task_to_run]}.first.execute!
    end

    # dynamically include another file into an existing configuration file.
    # by default, it looks for the include file in the same path as your tasks file you specified.
    def use arg
      if arg.is_a? Symbol
        begin
          dirname = File.dirname(@options[:task_file])
          instance_eval(File.open(File.dirname(File.expand_path(@options[:task_file])) + "/" + arg.to_s + ".rb").read)
        rescue Errno::ENOENT => e
          raise IncludeFileNotFound, "Could not find #{File.expand_path("./"+arg.to_s + ".rb")}! If the file is elsewhere, call it by using 'use '/path/to/file.rb'"
          exit(1)
        end
      else
        begin
          instance_eval(File.open(File.dirname(File.expand_path(@options[:task_file])) + "/" + arg).read)
        rescue Errno::ENOENT => e
          raise IncludeFileNotFound, "Could not find #{File.expand_path(arg)}! If the file is elsewhere, call it by using 'use '/path/to/file.rb'"
          exit(1)
        end
      end
    end
  
    # create a task.  Minimally, a task needs a :server specified to run the task on.
    #
    # The only special command in a task block is the "run" command, which will actually run the command
    # you specify on the server.  All others are stored in the options hash for later use.
    #
    # task_for :quick_push, :servers => :prod_servers do |r|
    #   # define a variable which you can use in other parts of your task, or a command set
    #   r.apache_binary "/usr/bin/apache2ctl"
    #
    #   # run a command set defined in the file. 
    #   r.command_set_name
    #
    #   # run other tasks.
    #   r.run "hostname"
    #
    #   r.run "#{r.apache_binary} restart"
    # end
    def task_for args, options = {}, &block
      # create a new task with the default options


      # make the server options immediately available on the task,
      # as if the task defined the options itself
      task_options = @options.merge(options)
      server = @options[:servers].select {|s| s.name.to_sym == options[:server]}.first
      raise ArgumentError, "Please specify a server for th task named #{args}!" if server.nil?

      task_options.merge! server.options

      t = Task.new(args, :options => task_options, :deployer => self)

      # then yield the block to set specific options
      yield t

      @options[:tasks] << t
    end

    # define a command set.
    # command_set :symlink, :depends => :svn_check_out do |c|
    #   c.run "rm -f _var_/current", "deploy[:dir]"
    #   c.run "ln -s _var_ _var_/current", :release_directory, "deploy[:dir]"
    # end
    #
    # The command set will look for the special token <tt>_var_</tt>, and replace it with the current value given as a param.
    # The first command will use the current value of <tt>deploy[:dir]</tt>, which may be defined globally or locally by the task.  
    # The second command uses two variables, <tt>release_directory</tt> and also <tt>deploy[:dir]</tt>.  For variables that are non-hashes, you can use a symbol to reference the variable.  
    #
    # The <tt>_var_</tt> token will be replaced by the variables given in order.  
    def command_set(name,options = {},&block)
      cs = CommandSet.new(name, @options.merge(options))
      yield cs
      @options[:command_sets] << cs
    end

    def server(name, options = {}, &block)
      server = Server.new(name, options)
      yield server if block_given?

      @options[:servers] ||= []
      @options[:servers] << server
      server
    end

    def active_recipe
      @options[:tasks].select {|r| r.name == @options[:task_to_run]}.first
    end

end
