# The deployer is the class that holds the overall params from the screwcap tasks file, and it is also in charge of running the requested task.
#
# The deployer can be thought of as the "global scope" of your tasks file.
class Deployer < Screwcap::Base

  # create a new deployer.
  def initialize(opts = {})
    opts = {:recipe_file => File.expand_path("./config/recipe.rb")}.merge opts
    super
    self.__options = opts
    self.__tasks = []
    self.__servers = []
    self.__command_sets = []
    self.__sequences = []

    # ensure that deployer options will not be passed to tasks
    opts.each_key {|k| self.delete_field(k) }

    log "Reading #{self.__options[:recipe_file]}\n" unless self.__options[:silent] == true

    file = File.open(File.expand_path("./#{self.__options[:recipe_file]}"))
    data = file.read

    instance_eval(data)
  end


  # create a task.  Minimally, a task needs a :server specified to run the task on.
  def task_for name, options = {}, &block
    t = Task.new(options.merge(:name => name, :nocolor => self.__options[:nocolor], :silent => self.__options[:silent], :deployment_servers => self.__servers), &block)
    clone_table_for(t)
    t.instance_eval(&block)
    self.__tasks << t
  end

  def command_set(name,options = {},&block)
    t = CommandSet.new(options.merge(:name => name), &block)
    clone_table_for(t)
    self.__command_sets << t
  end

  def server(name, options = {}, &block)
    server = Server.new(options.merge(:name => name, :servers => self.__servers, :silent => self.__options[:silent]))
    self.__servers << server
  end

  def gateway(name, options = {}, &block)
    server = Server.new(options.merge(:name => name, :is_gateway => true))
    self.__servers << server
  end

  def sequence(name, options = {}, &block)
    self.__sequences << Sequence.new(options.merge(:name => name, :deployment_task_names => self.__tasks.map(&:name)))
  end


  def run!(*tasks)
    tasks.flatten!
    # sanity check each task

    tasks_and_sequences = (self.__sequences.map(&:__name) + self.__tasks.map(&:__name))
    tasks.each do |task_to_run|
      raise(Screwcap::TaskNotFound, "Could not find task or sequence '#{task_to_run}' in recipe file #{self.__options[:recipe_file]}") unless tasks_and_sequences.include? task_to_run
    end

    tasks.each do |t| 
      sequence = self.__sequences.find {|s| s.__name == t }
      if sequence
        sequence.__task_names.each {|task_name| self.__tasks.find {|task| task.__name == task_name }.execute!}
      else
        self.__tasks.select {|task| task.name.to_s == t.to_s }.first.execute! 
      end
    end
    $stdout << "\033[0m"
  end

  # dynamically include another file into an existing configuration file.
  # by default, it looks for the include file in the same path as your tasks file you specified.
  def use arg
    if arg.is_a? Symbol
      begin
        dirname = File.dirname(self.__options[:recipe_file])
        instance_eval(File.open(File.dirname(File.expand_path(self.__options[:recipe_file])) + "/" + arg.to_s + ".rb").read)
      rescue Errno::ENOENT => e
        raise Screwcap::IncludeFileNotFound, "Could not find #{File.expand_path("./"+arg.to_s + ".rb")}! If the file is elsewhere, call it by using 'use '/path/to/file.rb'"
      end
    else
      begin
        instance_eval(File.open(File.dirname(File.expand_path(self.__options[:recipe_file])) + "/" + arg).read)
      rescue Errno::ENOENT => e
        raise Screwcap::IncludeFileNotFound, "Could not find #{File.expand_path(arg)}! If the file is elsewhere, call it by using 'use '/path/to/file.rb'"
      end
    end
  end


  private

  def clone_table_for(object)
    self.table.each do |k,v|
      object.set(k, v) unless [:__options, :__tasks, :__servers].include?(k)
    end
  end
end
