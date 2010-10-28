# The deployer is the class that holds the overall params from the screwcap tasks file, and it is also in charge of running the requested task.
#
# The deployer can be thought of as the "global scope" of your tasks file.
class Deployer < Screwcap::Base
  include MessageLogger

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

    Deployer.log "Reading #{self.__options[:recipe_file]}\n" unless self.__options[:silent] == true

    file = File.open(self.__options[:recipe_file])
    data = file.read

    instance_eval(data)
  end


  # create a task.  Minimally, a task needs a :server specified to run the task on.
  #   task_for :herd_the_cats, :server => :cat_server do
  #     ...
  #   end
  #
  #   task_for :herd_both, :servers => [:cat_server, :dog_server] do
  #     ...
  #   end
  #
  # The only other option that task_for accepts is *:parallel*.  If *parallel* => false, and a server has multiple addresses, then the task will be run serially, rather than all at the same time.
  #
  #   server :pig, :address => "pig.com"
  #   server :horse, :address => "horse.com"
  #   server :cats_and_dogs, :addresses => ["cat.com","dog.com"]
  #
  #   task_for :one_at_a_time, :servers => [:pig, :horse], :parallel => false
  #     run "serial_task" # this will be run on the pig server first, then on the horse server.
  #   end
  #
  #   task_for :one_at_a_time_2, :server => :cats_and_dogs, :parallel => false do
  #     run "serial_task" # this will be run on cat.com first, then on dog.com
  #   end
  #
  #   task_for :all_together_now, :servers => [:pig, :horse, :cats_and_dogs] do
  #     run "parallel_task"  # this task will be executed on all the addresses specified by the servers at the same time.
  #   end
  # ===A note about variable scope
  # ====Any variables you declare within a task are scoped to that task.
  #
  #     # in your deployment recipe...
  #     set :animal, "donkey"
  #
  #     task_for :thing, :server => :server do
  #       set :animal, "pig"
  #       run "pet #{animal}" # will run 'pet pig'
  #     end
  #
  # ====A command set that is called by a task will inherit all the variables set by the task.
  #   
  #     command_set :pet_the_animal do
  #       run "pet #{animal}"
  #     end
  #
  #     task_for :pet_pig do
  #       set :animal, "pig"
  #       pet_the_animal
  #     end
  #
  #     task_for :pet_horse do
  #       set :animal, "horse"
  #       pet_the_animal
  #     end
  #
  # ====Of course, you can also set variables within the command set as well, that are scoped only to that command set.
  #   
  #     command_set :pet_the_donkey do
  #       set :animal, "donkey"
  #       run "pet #{donkey}"
  #     end
  #
  # ====Any command sets that are nested within another command set will inerit all the variables from the parent command set.
  #
  def task name, options = {}, &block
    t = Task.new(options.merge(:name => name, :nocolor => self.__options[:nocolor], :silent => self.__options[:silent], :deployment_servers => self.__servers, :command_sets => self.__command_sets), &block)
    clone_table_for(t)
    t.instance_eval(&block)
    self.__tasks << t
  end
  alias :task_for :task

  # ====A *command set* is like a generic set of tasks that you intend to use in multiple tasks.
  #
  #     command_set :redundant_task do
  #       run "redundant_task"
  #     end
  #
  #     task_for :pet_pig, :server => :s1 do
  #       redundant_task
  #     end
  #
  #     task_for :pet_horse, :server => s2 do
  #       redundant_task
  #     end
  #
  # ====You can also nest command sets within other command sets.
  #     command_set :other_task do
  #       run "other_task"
  #     end
  #
  #     command_set :redundant_task do
  #       other_task
  #     end
  #
  #     task_for :pet_horse, :server => s2 do
  #       redundant_task
  #     end


  def command_set(name,options = {},&block)
    t = Task.new(options.merge(:name => name, :validate => false, :command_set => true, :command_sets => self.__command_sets), &block)
    clone_table_for(t)
    self.__command_sets << t
  end

  # ====A *server* is the address(es) that you run a *:task* on.
  #   server :myserver, :address => "abc.com", :password => "xxx"
  #   server :app_servers, :addresses => ["abc.com","def.com"], :keys => "~/.ssh/my_key"
  #
  # ==== Options
  # * A server must have a *:user*.
  # * Specify *:address* or *:addresses*
  # * A *:gateway*.  See the section about gateways for more info.
  # * All Other options will be passed directly to Net::SSH.
  #   * *:keys* can be used to specify the key to use to connect to the server
  #   * *:password* specify the password to connect with.  Not recommended.  Use keys.
  def server(name, options = {}, &block)
    server = Server.new(options.merge(:name => name, :servers => self.__servers, :silent => self.__options[:silent]))
    self.__servers << server
  end

  # ====A *Gateway* is an intermediary computer between you and a *:server*.
  #   gateway :mygateway, :address => "abc.com", :keys => "~/.ssh/key"
  #   server :myserver, :address => "192.168.1.2", :password => "xxx", :gateway => :mygateway
  #
  # * Gateways have the same option as a *:server*.
  # * You can specify :gateway => :mygateway in the *:server* definition.
  def gateway(name, options = {}, &block)
    server = Server.new(options.merge(:name => name, :is_gateway => true))
    self.__servers << server
  end

  # ====A *Sequence* will run a set of tasks in order.
  #
  #   task_for :do_this, :server => :myserver
  #     ...
  #   end
  #
  #   task_for :do_that, :server => :myserver
  #     ...
  #   end
  #
  #   task_for :do_the_other_thing, :server => :myserver
  #     ...
  #   end
  #
  #   sequence :do_them_all, :tasks => [:do_this, :do_that, :do_the_other_thing]
  #
  # ====Sequences can be called just like tasks.
  # ====Options
  # * :tasks - the list of tasks to run, as an array of symbols.
  def sequence(name, options = {}, &block)
    self.__sequences << Sequence.new(options.merge(:name => name, :deployment_task_names => self.__tasks.map(&:name)))
  end

  # ====Run one or more tasks or sequences.
  # * :tasks - the list of tasks to run, as an array of symbols.
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
        sequence.__task_names.each {|task_name| Runner.execute! self.__tasks.find {|task| task.__name == task_name }, self.__options}
      else
        Runner.execute! self.__tasks.select {|task| task.name.to_s == t.to_s }.first, self.__options
      end
    end
    $stdout << "\033[0m"
  end

  # ====Use will dynamically include another file into an existing configuration file.
  # Screwcap currently looks in the same directory as the current recipe file.
  #
  # if you have my_deployment_tasks.rb in the same directory as your recipe file...
  # and my deployment_tasks includes more tasks, servers, sequences, etc.
  #   use :my_deployment_tasks
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
      object.set(k, v) unless [:__options, :__tasks, :__servers, :__command_sets].include?(k)
    end
  end
end
