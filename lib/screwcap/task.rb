class Task < Screwcap::Base
  def initialize(opts = {}, &block)
    super
    self.__name = opts[:name]
    self.__options = opts
    self.__commands = []
    self.__command_sets = []
    validate
  end

  # run a command. basically just pass it a string containing the command you want to run.
  def run arg, options = {}
    if arg.class == Symbol
      self.__commands << self.send(arg)
    else
      self.__commands << arg
    end
  end

  # execute the task.  This is automagically called by the deployer.
  def execute!
    threads = []

    addresses = self.__servers.select {|s| self.__options[:servers].include?(s.name)}.map {|s| s.__options[:addresses] }.flatten
    addresses.each do |address|
      threads << Thread.new(address) do |address|
        server = self.__servers.find {|s| s.__options[:addresses].include?(address) }
        begin
          $stdout << "\n*** BEGIN deployment Recipe for #{address}\n" unless self.__options[:silent] == true

          Net::SSH.start(address, server.__options[:user], server.__options.reject {|k,v| [:user,:addresses].include?(k)}) do |ssh|
            error = false
            self.__commands.each do |command|
              next if error and !self.__options[:continue_on_errors]
              $stdout <<  "    I:  #{command}\n" unless self.__options[:silent] == true

              ssh.exec! command do |ch,stream,data|
                if stream == :stderr
                  error = true
                  $stderr << "    E: #{data}"
                else
                  $stdout <<  "    O:  #{data}" unless self.__options[:silent] == true
                end
              end # ssh.exec
            end # commands.each
          end # net.ssh start
        rescue Exception => e
          $stderr << "    F: #{e}"
        ensure
          $stdout << "\n*** END deployment Recipe for #{address}\n" unless self.__options[:silent] == true
        end
      end # threads << 
    end #addresses.each
    threads.each {|t| t.join }
  end

  protected

  def method_missing(m, *args)
    if m.to_s[0..1] == "__" or [:run].include?(m) or m.to_s.reverse[0..0] == "="
      super(m, args.first) 
    else
      if cs = self.__command_sets.find {|cs| cs.name == m }
        # eval what is in the block
        clone_table_for(cs)
        cs.__commands = []
        cs.instance_eval(&cs.__block)
        self.__commands += cs.__commands
      else
        raise NoMethodError, "Undefined method '#{m.to_s}' for task :#{self.name.to_s}"
      end
    end
  end

  private

  def clone_table_for(object)
    self.table.each do |k,v|
      object.set(k, v) unless [:__command_sets, :name, :__commands, :__options].include?(k)
    end
  end

  def validate
    raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." if (self.__options[:servers].nil? or self.__options[:servers] == []) and self.__options[:server].nil?
    self.__options[:servers] = [self.__options[:servers]] unless self.__options[:servers].class == Array
    self.__options[:servers] = [self.__options[:server]] if self.__options[:server]
    self.__options[:servers].each do |server|
      # ensure we find this server declared
      raise Screwcap::ConfigurationError, "Could not find a server to run this task on.  Please specify :server => :servername or :servers => [:server1, :server2] in the task_for directive." unless self.__options[:servers].include?(server)

    end
  end
end
