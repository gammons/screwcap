class Server < Screwcap::Base
  def initialize(opts = {})
    super(opts)
    self.__options = opts
    self.__name = opts[:name]
    self.__options[:keys] = [self.__options.delete(:key)] if self.__options[:key]
    self.__options[:addresses] = [self.__options.delete(:address)] if self.__options[:address] and self.__options[:addresses].nil?
    validate
    self
  end

  protected

  def validate
    raise Screwcap::InvalidServer, "Please specify an address for the server #{self.__options[:name]}." if self.__options[:addresses].nil? or self.__options[:addresses] == [nil]
    raise Screwcap::InvalidServer, "Please specify a username to use for the server #{self.__options[:name]}." if self.__options[:user].nil?
  end
end
