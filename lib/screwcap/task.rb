class Task < Screwcap::Base
  def initialize(opts = {}, &block)
    super(opts)
    self.options = opts
    self.command = {}
    self.loaded_command_sets = []
    self.command_order = []
    self.commands = []
  end

  # run a command. basically just pass it a string containing the command you want to run.
  def run arg, options = {}
    if arg.class == Symbol
      self.commands << self.send(arg)
    else
      self.commands << arg
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
