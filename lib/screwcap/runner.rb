class Runner
  include MessageLogger

  def self.execute! task, options
    @task = task; @options = options
    threads = []
    @task.__servers.each do |_server|
      _server.__addresses.each do |_address|
        if task.__options[:parallel] == false
          execute_on(_server, _address)
        else
          threads << Thread.new(_server, _address) { |server, address| execute_on(server, address) }
        end
      end
    end
    threads.each {|t| t.join }
  end

  private

  def self.execute_on(server, address) 
    begin
      log "\n*** BEGIN executing task #{@task.__name} on #{server.name} with address #{address}\n", :color => :blue

      server.__with_connection_for(address) do |ssh|
        failed_command = nil
        @task.__commands.each do |command|
          if run_command(ssh, address, server, command) != 0 and command[:onfailure]
            failed_command = command
            break
          end
        end
        if failed_command
          @task.__commands = []
          @task.send(failed_command[:onfailure])
          @task.__commands.each { |command| run_command(ssh, address, server, command) }
        end
      end
    rescue Net::SSH::AuthenticationFailed => e
      raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
    #rescue Exception => e
    #  errorlog "    F: (#{address}): #{e}", :color => :red
    #ensure
    #  log "*** END executing task #{@task.__name} on #{server.name} with address #{address}\n\n", :color => :blue
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


  def self.run_command(ssh, address, server, command)
    if command[:type] == :remote
      log "    I: (#{address}):  #{command[:command]}\n", :color => :green
      stdout, stderr, exit_code, exit_signal = ssh_exec! ssh, command[:command]
      log("    O: (#{address}):  #{stdout}", :color => :green) unless stdout.blank?
      errorlog("    O: (#{address}):  #{stderr}", :color => :red) unless stderr.blank?
      errorlog("    E: (#{address}): #{command[:command]} return exit code: #{exit_code}\n", :color => :red) if exit_code != 0
      return exit_code
    elsif command[:type] == :local
      ret = `#{command[:command]}`
      if $?.to_i == 0
        log "    I: (local):  #{command[:command]}\n", :color => :blue
        log "    O: (local):  #{ret}\n", :color => :blue
      else
        log "    I: (local):  #{command[:command]}\n", :color => :blue
        errorlog "    O: (local):  #{ret}\n", :color => :red
        errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
      end
      return $?
    elsif command[:type] == :scp
      log "    I: (#{address}): SCP #{command[:local]} to #{server.__user}@#{address}:#{command[:remote]}\n", :color => :green
      server.__upload_to!(address, command[:local], command[:remote])

      # this will need to be improved to allow for :onfailure
      return 0
    end

  end
end
