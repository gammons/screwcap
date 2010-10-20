class Server < Screwcap::Base
  def initialize(opts = {})
    super
    self.__options = opts
    self.__name = opts[:name]
    self.__servers = opts[:servers]
    self.__user = opts[:user]
    self.__options[:keys] = [self.__options.delete(:key)] if self.__options[:key]

    if self.__options[:address] and self.__options[:addresses].nil?
      self.__addresses = [self.__options.delete(:address)] 
    else
      self.__addresses = self.__options[:addresses]
    end

    validate

    self
  end

  def __with_connection(&block)
    self.__addresses.each do |address|  
      if self.__options[:gateway]
        gateway = self.__servers.select {|s| s.__options[:is_gateway] == true }.find {|s| s.__name == self.__options[:gateway] }
        log "  *** BEGIN execute on #{address}\n" unless self.__options[:silent] == true
        gateway.__get_gateway_connection.ssh(address, self.__user, self.__options.reject {|k,v| [:user, :gateway, :is_gateway, :addresses, :name, :servers].include?(k)}) do |ssh|
          yield ssh
        end
        log "  *** END execute on #{address}\n"
      else
        Net::SSH.start(address, self.__user, self.__options.reject {|k,v| [:user,:addresses, :gateway, :is_gateway, :name, :servers].include?(k)}) do |ssh|
          yield ssh
        end
      end
    end
  end

  protected

  def __get_gateway_connection
    self.__connection ||= Net::SSH::Gateway.new(self.__addresses.first, self.__user, self.__options.reject {|k,v| [:user,:addresses, :gateway, :name, :servers, :is_gateway].include?(k)})
  end

  private

  def validate
    raise Screwcap::InvalidServer, "Please specify an address for the server #{self.__options[:name]}." if self.__addresses.blank?
    raise Screwcap::InvalidServer, "Please specify a username to use for the server #{self.__name}." if self.__user.nil?
    raise Screwcap::InvalidServer, "A gateway can have only one address" if self.__addresses.size > 1 and self.__options[:is_gateway] == true
  end
end
