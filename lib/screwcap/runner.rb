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

    if options[:servers] and task.__servers
      begin
        servers = options[:servers].select {|s| task.__servers.include? s.__name }
        connections = servers.map {|server| server.connect! }.flatten
      rescue Net::SSH::AuthenticationFailed => e
        raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
      end
    end

    _log "\nExecuting task #{task.name}\n", :color => :blue

    task.__built_commands.each do |command|
      ret = case command[:type]
      when :remote
        threads = []
        connections.each do |connection|
          threads << Thread.new(connection) do |conn|
            run_remote_command(command, conn, options)
          end
        end
        threads.each {|t| t.join }
      when :local
        ret = `#{command[:command]}`
        command[:stdout] = ret
        if $?.to_i == 0
          if options[:verbose]
            _log "    O: #{ret}\n", :color => :green
          else
            _log(".", :color => :green)
          end
        else
          _errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
        end
        ret
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
    task.__built_commands # for tests
  end

  private

  def self.run_remote_command(command, ssh, options)
    stdout, stderr, exit_code, exit_signal = ssh_exec! ssh, command[:command]
    command[:stdout] = stdout
    command[:stderr] = stderr
    command[:exit_code] = exit_code
    if exit_code == 0
      if @@verbose
        _log("    I: #{command[:command]}\n", :color => :green)
        _log("    O: #{command[:stdout]}\n", :color => :green)
      else
        _log(".", :color => :green)
      end
    else
      _errorlog("    E: (#{options[:address]}): #{command[:command]} return exit code: #{exit_code}\n", :color => :red) if exit_code != 0
    end
    exit_code
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
