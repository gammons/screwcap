class Server < Screwcap::Base

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
  def initialize(opts = {})
    super
    self.__name = opts.delete(:name)
    self.__user = opts.delete(:user)
    self.__options[:keys] = [opts.delete(:key)] if opts[:key]

    servers = opts.delete(:servers)
    self.__gateway = servers.select {|s| s.__options[:is_gateway] == true }.find {|s| s.__name == opts[:gateway] } if servers

    self.__options = opts

    if self.__options[:address] and self.__options[:addresses].nil?
      self.__addresses = [self.__options.delete(:address)] 
    else
      self.__addresses = self.__options[:addresses]
    end

    validate

    self
  end

  def __with_connection_for(address, &block)
    if self.__gateway
      __gateway.__get_gateway_connection.ssh(address, self.__user, options_for_net_ssh) do |ssh|
        yield ssh
      end
    else
      Net::SSH.start(address, self.__user, options_for_net_ssh) do |ssh|
        yield ssh
      end
    end
  end

  def __upload_to!(address, local, remote)
    self.__with_connection_for(address) {|ssh| ssh.scp.upload! local, remote }
  end

  protected

  def __get_gateway_connection
    self.__connection ||= Net::SSH::Gateway.new(self.__addresses.first, self.__user, self.__options.reject {|k,v| [:user,:addresses, :gateway, :name, :servers, :is_gateway].include?(k)})
  end

  private

  def validate
    raise Screwcap::InvalidServer, "Please specify an address for the server #{self.__options[:name]}." if self.__addresses.nil? or self.__addresses.size == 0
    raise Screwcap::InvalidServer, "Please specify a username to use for the server #{self.__name}." if self.__user.nil?
    raise Screwcap::InvalidServer, "A gateway can have only one address" if self.__addresses.size > 1 and self.__options[:is_gateway] == true
  end

  def options_for_net_ssh
    self.__options.reject {|k,v| [:user,:addresses, :gateway, :is_gateway, :name, :silent, :servers].include?(k)}
  end
end
