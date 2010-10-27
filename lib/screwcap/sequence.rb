class Sequence < Screwcap::Base

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
  def initialize(opts = {})
    super
    self.__options = opts
    self.__name = opts[:name]
    self.__deployment_task_names = opts[:deployment_task_names]
    self.__task_names = opts[:tasks]
    validate
  end

  private

  def validate
    self.__task_names.each do |tn|
      raise(Screwcap::ConfigurationError, "Could not find task #{tn} in the deployment recipe.") unless self.__deployment_task_names.include?(tn)
    end
  end
end
