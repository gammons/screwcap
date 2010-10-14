class Task < Screwcap::Base
  def initialize(opts = {}, &block)
    super(opts)
    self.options = opts
    self.command = {}
    self.loaded_command_sets = []
    self.command_order = []
    self.commands = []
    #$stdout << "BEFORE YIELD\n"
    #yield
    #$stdout << "AFTER YIELD\n"
  end

  #  # first try our command sets.
  #  if cs = self.command_sets.select {|cs| cs.name == m}.first

  #    # check for dependencies
  #    if cs.options[:depends]
  #      unless @loaded_command_sets.find {|lcs| lcs == cs.options[:depends] }
  #        raise Screwcap::CommandSetDependencyError, "Command :#{cs.name} depends on command :#{cs.options[:depends]} to be run first!"
  #      end
  #    end
  #    
  #    @loaded_command_sets << cs.name

  #    # the correct way to do it is to merge in our options and let the cs options override ours, while the task options override the default.
  #    commands = cs.compile_commands_with(self.options)

  #    commands.each {|c| run c[:compiled_command] }
  #    return
  #  end

  #  # otherwise comb the options
  #  #return @options[m.to_sym] = args.first if args and args.size == 1
  #  #return @options[m.to_sym] = args if args and args != []
  #  #@options[m.to_sym]
  #end

  # run a command. basically just pass it a string containing the command you want to run.
  def run arg, options = {}
    self.commands << arg.first
    #increment = 0
    #self.command_order.each { |command| increment += 1 if command[:command].to_s[0..2] == "run" }
    #debugger

    #run_name = "run#{increment}".to_sym

    #command_details = options.merge({:command => run_name})

    #self.command_order << command_details
    #self.commands[run_name] ||= []
    #if arg.is_a?(Array)
    #  self.commands[run_name] += arg
    #else
    #  self.commands[run_name] << arg
    #end
  end

  def method_missing(m, *args, &block)
    begin
      super(m, args.first)
    rescue NoMethodError
      super((m.to_s + "=").to_sym, args.first)
    end
  end


  protected

  # execute the task.  This is automagically called by the deployer.
  def execute!
    threads = []
    #raise Screwcap::NoServersDefined, "No Servers Defined! Please define a server in the global section of your task file, or in a specific task." if @deployer.options[:servers].nil?

    # select the server to use
    #server = @deployer.options[:servers].select {|s| s.name == options[:server] }.first

    #raise Screwcap::NoServerSelected, "Please tell the task which server you want to run the task on." if server.nil?

    server.server_options[:addresses].each do |address|
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
    threads.each {|t| t.join }
  end
end
