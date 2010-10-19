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

    log "Attempting to read #{self.__options[:recipe_file]}\n" unless self.__options[:silent] == true

    file = File.open(File.expand_path("./#{self.__options[:recipe_file]}"))
    data = file.read

    instance_eval(data)
  end


  # create a task.  Minimally, a task needs a :server specified to run the task on.
  def task_for name, options = {}, &block
    t = Task.new(options.merge(:name => name, :silent => self.__options[:silent], :deployment_servers => self.__servers), &block)
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
    server = Server.new(options.merge(:name => name, :servers => self.__servers))
    self.__servers << server
  end

  def gateway(name, options = {}, &block)
    server = Server.new(options.merge(:name => name, :is_gateway => true))
    self.__servers << server
  end


  def run!(*tasks)
    # sanity check each task
    self.__tasks.each do |task| 
      tasks.each do |task_to_run|
        raise(Screwcap::TaskNotFound, "Could not find task '#{task_to_run}' in recipe file #{self.__options[:recipe_file]}") unless self.__tasks.map(&:name).include? task_to_run
      end
    end
    tasks.each { |t| self.__tasks.select {|task| task.name.to_s == t.to_s }.first.execute! }
  end

  private

  def clone_table_for(object)
    self.table.each do |k,v|
      object.set(k, v) unless [:__options, :__tasks, :__servers].include?(k)
    end
  end
end
