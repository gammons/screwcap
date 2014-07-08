module Screwcap
  class Runner
    include MessageLogger
    @@silent = false

    def self.execute! options
      @@silent = options[:silent]
      @@verbose = options[:verbose]
      task = options[:task]

      if (task.__servers.nil? or task.__servers == [] or task.__servers.compact == []) and task.__built_commands.any? {|c| c[:type] == :remote or c[:type] == :scp }
        raise Screwcap::ConfigurationError, "The task #{task.name} includes remote commands, however no servers were defined for this task."
      end

      connections = []

      _log "\nExecuting task #{task.name}\n", :color => :blue

      if task.__options[:parallel] == false
        run_serially(task, options)
      else
        run_parallel(task, options)
      end
    end

    private

    def self.run_serially(task, options)
      results = []
      connections = []
      if options[:servers] and task.__servers
        servers = options[:servers].select {|s| task.__servers.flatten.include? s.__name }
        connections = servers.map {|server| server.connect! }.flatten
      end

      connections.each do |connection|
        task.__built_commands.each do |command|
          ret = case command[:type]
          when :remote
            results << run_remote_command(command, connection[:connection], options)
            if command[:block]
              opts = task.__options.clone.merge(:stderr => command[:stderr], :stdout => command[:stdout], :exit_code => command[:exit_code])
              opts[:servers] = task.__servers
              opts[:name] = "Run results"

              inner_task = Task.new(opts, &command[:block])
              inner_task.__build_commands(options[:tasks])
              results << self.execute!(options.merge(:task => inner_task))
            end
          when :local
            result = {}
            result[:stdout] = `#{command[:command]}`
            result[:exit_code] = $?.to_i
            results << result
            if $?.to_i == 0
              if options[:verbose]
                _log "    O: #{ret}\n", :color => :green
              else
                _log(".", :color => :green)
              end
            else
              _errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
            end
          when :scp
            threads = []
            servers.each do |server|
              threads << Thread.new(server) { |_server| _server.upload! command[:local], command[:remote] }
            end
            threads.each {|t| t.join }
          when :block
            command[:block].call
          end
        end
      end
      _log "Complete\n", :color => :blue
      results
    end

    def self.run_parallel(task, options)
      results = []
      connections = []
      if options[:servers] and task.__servers
        servers = options[:servers].select {|s| task.__servers.flatten.include? s.__name }
        connections = servers.map {|server| server.connect! }.flatten
      end

      task.__built_commands.each do |command|
        ret = case command[:type]
        when :remote
          if command[:parallel] == false or command[:block]
            connections.each do |connection|
              results << run_remote_command(command, connection[:connection], options)
              if command[:block]
                opts = task.__options.clone.merge(:stderr => command[:stderr], :stdout => command[:stdout], :exit_code => command[:exit_code])
                opts[:servers] = task.__servers
                opts[:name] = "Run results"

                inner_task = Task.new(opts, &command[:block])
                inner_task.__build_commands(options[:tasks])
                results << self.execute!(options.merge(:task => inner_task))
              end
            end
          else
            threads = []
            connections.each do |connection|
              threads << Thread.new(connection) do |conn|
                results << run_remote_command(command, conn[:connection], options)
              end
            end
            threads.each {|t| t.join }
          end
        when :local
          result = {}
          result[:stdout] = `#{command[:command]}`
          result[:exit_code] = $?.to_i
          results << result
          if $?.to_i == 0
            if options[:verbose]
              _log "    O: #{ret}\n", :color => :green
            else
              _log(".", :color => :green)
            end
          else
            _errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
          end
        when :scp
          threads = []
          servers.each do |server|
            threads << Thread.new(server) { |_server| _server.upload! command[:local], command[:remote] }
          end
          threads.each {|t| t.join }
        when :block
          command[:block].call
        end
      end
      _log "Complete\n", :color => :blue
      results
    end

    def self.run_remote_command(command, ssh, options)
      stdout, stderr, exit_code, exit_signal = ssh_exec! ssh, command[:command]
      ret = {:command => command[:command]}
      ret[:stdout] = command[:stdout] = stdout
      ret[:stderr] = command[:stderr] = stderr
      ret[:exit_code] = command[:exit_code] = exit_code
      if exit_code == 0
        if @@verbose
          _log("    I: #{command[:command]}\n", :color => :green)
          _log("    O: #{command[:stdout]}\n", :color => :green)
        else
          _log(".", :color => :green)
        end
      else
        _log("    I: #{command[:command]}\n", :color => :green)
        _errorlog("    E: (exit code: #{exit_code}) #{command[:stderr]} \n", :color => :red)
      end
      ret
    end

    # courtesy of flitzwald on stackoverflow
    # http://stackoverflow.com/questions/3386233/how-to-get-exit-status-with-rubys-netssh-library
    def self.ssh_exec!(ssh, command)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          channel.on_data do |ch,data|
            stdout_data+=data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data+=data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
      end
      ssh.loop
      [stdout_data, stderr_data, exit_code, exit_signal]
    end

    def self._log(message, options)
      return if @@silent == true
      log(message, options)
    end

    def self._errorlog(message, options)
      return if @@silent == true
      errorlog(message, options)
    end
  end
end
