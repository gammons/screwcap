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

    # ensure that deployer options will not be passed to tasks
    opts.each_key {|k| self.delete_field(k) }

    $stdout << "Attempting to read #{self.__options[:recipe_file]}\n" unless self.__options[:silent] == true

    file = File.open(File.expand_path("./#{self.__options[:recipe_file]}"))
    data = file.read

    instance_eval(data)
  end

  def run!(*tasks)
    # sanity check each task
    self.__tasks.each do |t| 
      raise(Screwcap::TaskNotFound, "Could not find task '#{t}' in recipe file #{self.__options[:recipe_file]}") unless self.__tasks.map(&:name).include? t
    end
    tasks.each { |t| self.__tasks.select {|task| task.name.to_s == t.to_s }.first.execute! }
  end

  # create a task.  Minimally, a task needs a :server specified to run the task on.
  def task_for name, options = {}, &block
    server = self.__servers.select {|s| s.name.to_sym == options[:server]}.first
    raise ArgumentError, "Please specify a server for the task named #{args}!" if server.nil?

    t = Task.new(options.merge(:name => name), &block)
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
    server = Server.new(options.merge(:name => name))
    server.instance_eval(&block) if block_given?

    self.__servers << server
  end

  private

  def clone_table_for(object)
    self.table.each do |k,v|
      object.set(k, v) unless [:__tasks, :__servers].include?(k)
    end
  end
end
