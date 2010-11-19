class Runner
  include MessageLogger
  @@silent = false

  def self.execute! options
    @@silent = options[:silent]
    begin
      _log "\n*** BEGIN executing task #{options[:name]} on #{options[:server].name} with address #{options[:address]}\n", :color => :blue unless options[:silent] == true
      options[:server].__with_connection_for(options[:address]) do |ssh|
        options[:commands].each do |command|
          ret = run_command(command, ssh, options)
          break if ret != 0 and command[:abort_on_fail] == true
        end
      end
    rescue Net::SSH::AuthenticationFailed => e
      raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
    #rescue Exception => e
    #  _errorlog "    F: (#{options[:address]}): #{e}", :color => :red
    ensure
      _log "*** END executing task #{options[:name]} on #{options[:server].name} with address #{options[:address]}\n\n", :color => :blue
    end
    options[:commands] # for tests
  end

  def self.execute_locally! options
    @@silent = options[:silent]
    _log "\n*** BEGIN executing local task #{options[:name]}\n", :color => :blue
    options[:commands].each do |command|
      command[:stdout] = ret = `#{command[:command]}`
      
      if $?.to_i == 0
        _log "    I: (local):  #{command[:command]}\n", :color => :blue
        _log("    O: (local):  #{ret}\n", :color => :blue) unless ret.nil? or ret == ""
      else
        _log "    I: (local):  #{command[:command]}\n", :color => :blue
        _errorlog("    O: (local):  #{ret}\n", :color => :red) unless ret.nil? or ret == ""
        _errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
      end
    end
    _log "\n*** END executing local task #{options[:name]}\n", :color => :blue
    options[:commands]
  end

  private

  def self.run_command(command, ssh, options)
    if command[:type] == :remote
      _log "    I: (#{options[:address]}):  #{command[:command]}\n", :color => :green
      stdout, stderr, exit_code, exit_signal = ssh_exec! ssh, command[:command]
      command[:stdout] = stdout
      command[:stderr] = stderr
      _log("    O: (#{options[:address]}):  #{stdout}", :color => :green) unless stdout.nil? or stdout == ""
      _errorlog("    O: (#{options[:address]}):  #{stderr}", :color => :red) unless stderr.nil? or stderr == ""
      _errorlog("    E: (#{options[:address]}): #{command[:command]} return exit code: #{exit_code}\n", :color => :red) if exit_code != 0
      return exit_code
    elsif command[:type] == :local
      ret = `#{command[:command]}`
      command[:stdout] = ret
      if $?.to_i == 0
        _log "    I: (local):  #{command[:command]}\n", :color => :blue
        _log "    O: (local):  #{ret}\n", :color => :blue
      else
        _log "    I: (local):  #{command[:command]}\n", :color => :blue
        _errorlog "    O: (local):  #{ret}\n", :color => :red
        _errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
      end
      return $?
    elsif command[:type] == :scp
      _log "    I: (#{options[:address]}): SCP #{command[:local]} to #{options[:server].__user}@#{options[:address]}:#{command[:remote]}\n", :color => :green
      options[:server].__upload_to!(options[:address], command[:local], command[:remote])

      # this will need to be improved to allow for :onfailure
      return 0
    end
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
