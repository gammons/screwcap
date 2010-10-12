class Server < Screwcap::Base
  attr_accessor :options, :commands, :command_order, :deployer, :loaded_command_sets, :server_options, :name

  def initialize(name,server_options = {})
    @options, @server_options = {}, server_options
    @name = name
    @server_options[:keys] = [@server_options.delete(:key)] if server_options[:key]
    @server_options[:addresses] = [@server_options.delete(:address)] if @server_options[:address] and @server_options[:addresses].nil?

    validate

    @deployer = options[:deployer]
  end

  protected

  def validate
    raise Screwcap::InvalidServer, "Please specify an address for the server #{@server_options[:name]}." if @server_options[:addresses].nil? or @server_options[:addresses] == [nil]
    raise Screwcap::InvalidServer, "Please specify a username to use for the server #{@server_options[:name]}." if @server_options[:user].nil?
  end
end
