class Server < Screwcap::Base
  def initialize(opts = {})
    super(opts)
    self.options = opts
    self.name = opts[:name]
    self.options[:keys] = [self.options.delete(:key)] if self.options[:key]
    self.options[:addresses] = [self.options.delete(:address)] if self.options[:address] and self.options[:addresses].nil?
    validate
    self
  end

  protected

  def validate
    raise Screwcap::InvalidServer, "Please specify an address for the server #{self.options[:name]}." if self.options[:addresses].nil? or self.options[:addresses] == [nil]
    raise Screwcap::InvalidServer, "Please specify a username to use for the server #{options[:name]}." if self.options[:user].nil?
  end
end
