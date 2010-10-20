class Sequence < Screwcap::Base
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
