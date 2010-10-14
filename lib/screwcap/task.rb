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

    self.__options[:servers].each do |server_def|
      debugger
      server_def.__options[:addresses].each do |address|
        threads << Thread.new(server) do |server|

          output = []
          begin
            $stdout << "\n*** BEGIN deployment Recipe for #{address}\n" unless options[:silent] == true

            Net::SSH.start(address, server.server_options[:user], server.server_options.reject {|k,v| [:user,:addresses].include?(k)}) do |ssh|
              error = false
              @command_order.each do |command|

                # callbacks.
                if command[:before]
                  if command[:before].is_a?(Array)
                    command[:before].each do |bc|
                      @deployer.send(bc,command) if @deployer.respond_to?(bc)
                    end
                  else
                    @deployer.send(command[:before],command) if @deployer.respond_to?(command[:before])
                  end
                end

                @commands[command[:command]].each do |c|
                  next if error and !self.options[:continue_on_errors]
                  $stdout <<  "    I:  #{c}\n" unless options[:silent] == true
                  command[:input] = c
                  ssh.exec! c do |ch,stream,data|

                    # store the command's output
                    command[:output] ||= []
                    command[:output] << data

                    if stream == :stderr
                      command[:status] = :error
                      error = true
                      $stderr << "    E: #{data}"
                    else
                      command[:status] = :success
                      $stdout <<  "    O:  #{data}" unless options[:silent] == true
                    end

                  end # ssh.exec
                end # @commands.each

                # handle the after callback
                if command[:after]
                  if command[:after].is_a?(Array)
                    command[:after].each do |ac|
                      @deployer.send(ac,command) if @deployer.respond_to?(ac)
                    end
                  else
                    @deployer.send(command[:after],command) if @deployer.respond_to?(command[:after])
                  end
                end

              end # command order.each
            end # net.ssh start
          rescue Exception => e
            $stderr << "    F: #{e}"
          end # begin
            $stdout << "*** END deployment Recipe for #{address}\n" unless options[:silent] == true
        end # thread.new
      end
    end
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
