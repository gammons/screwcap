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
    self.__task_names = opts[:tasks]
  end
end
