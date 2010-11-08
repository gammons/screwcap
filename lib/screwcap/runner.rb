class Runner
  include MessageLogger

  def self.execute! task, options
    @task = task; @options = options
    threads = []
    if @task.__options[:local] == true
      log "\n*** BEGIN executing local task #{@task.__name}\n", :color => :blue
      @task.__commands.each do |command|
        ret = `#{command[:command]}`
        if $?.to_i == 0
          log "    I: (local):  #{command[:command]}\n", :color => :blue
          log("    O: (local):  #{ret}\n", :color => :blue) unless ret.nil? or ret == ""
        else
          log "    I: (local):  #{command[:command]}\n", :color => :blue
          errorlog("    O: (local):  #{ret}\n", :color => :red) unless ret.nil? or ret == ""
          errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
        end
      end
      log "\n*** END executing local task #{@task.__name}\n", :color => :blue
    else
      @task.__servers.each do |_server|
        _server.__addresses.each do |_address|
          if task.__options[:parallel] == false
            run_commands_on(_server, _address)
          else
            threads << Thread.new(_server, _address) { |server, address| run_commands_on(server, address) }
          end
        end
      end
    end
    threads.each {|t| t.join }
  end

  private

  def self.run_commands_on(server, address) 
    begin
      log "\n*** BEGIN executing task #{@task.__name} on #{server.name} with address #{address}\n", :color => :blue
      server.__with_connection_for(address) do |ssh|
        execute_commands(@task.__commands, :ssh => ssh, :address => address, :server => server)
      end
    rescue Net::SSH::AuthenticationFailed => e
      raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
    rescue Exception => e
      errorlog "    F: (#{address}): #{e}", :color => :red
    ensure
      log "*** END executing task #{@task.__name} on #{server.name} with address #{address}\n\n", :color => :blue
    end
  end

  def self.execute_commands(commands, options = {})
    commands.each do |command|
      if ret = run_command(command, options) != 0 
        if command[:onfailure]
          run_on_failure = @task.__command_sets.find {|cs| cs.__name == command[:onfailure] }
          raise(ArgumentError, "Could not find :onfailure command_set named '#{command[:onfailure]}'!") if run_on_failure.nil?
          execute_commands(@task.__commands_for(command[:onfailure]), options)
          break if command[:abort] == true
        elsif command[:yes] and ret == 1
          to_run = @task.__command_sets.find {|cs| cs.__name == command[:yes] }
          raise(ArgumentError, "Could not find :yes command_set named '#{command[:yes]}'!") if to_run.nil?
          execute_commands(@task.__commands_for(command[:yes]), options)
          break if command[:abort] == true
        elsif command[:no] and ret == 2
          to_run = @task.__command_sets.find {|cs| cs.__name == command[:no] }
          raise(ArgumentError, "Could not find :no command_set named '#{command[:no]}'!") if to_run.blank?
          execute_commands(@task.__commands_for(command[:no]))
        end
      end
    end
  end


  def self.run_command(command, options)
    if command[:type] == :remote
      log "    I: (#{options[:address]}):  #{command[:command]}\n", :color => :green
      stdout, stderr, exit_code, exit_signal = ssh_exec! options[:ssh], command[:command]
      command[:stdout] = stdout
      command[:stderr] = stderr
      log("    O: (#{options[:address]}):  #{stdout}", :color => :green) unless stdout.nil? or stdout == ""
      errorlog("    O: (#{options[:address]}):  #{stderr}", :color => :red) unless stderr.nil? or stderr == ""
      errorlog("    E: (#{options[:address]}): #{command[:command]} return exit code: #{exit_code}\n", :color => :red) if exit_code != 0
      return exit_code
    elsif command[:type] == :local
      ret = `#{command[:command]}`
      command[:stdout] = ret
      if $?.to_i == 0
        log "    I: (local):  #{command[:command]}\n", :color => :blue
        log "    O: (local):  #{ret}\n", :color => :blue
      else
        log "    I: (local):  #{command[:command]}\n", :color => :blue
        errorlog "    O: (local):  #{ret}\n", :color => :red
        errorlog("    E: (local): #{command[:command]} return exit code: #{$?}\n", :color => :red) if $? != 0
      end
      return $?
    elsif command[:type] == :ask
      answer = ""
      while answer == ""
        log (command[:command] + " (y/n) "), :color => :bluebold
        answer = get_input
      end
      return 1 if command[:yes] and ["yes","y"].include? answer.downcase 
      return 2 if command[:no] and ["no","n"].include? answer.downcase 
    elsif command[:type] == :scp
      log "    I: (#{options[:address]}): SCP #{command[:local]} to #{options[:server].__user}@#{options[:address]}:#{command[:remote]}\n", :color => :green
      options[:server].__upload_to!(options[:address], command[:local], command[:remote])

      # this will need to be improved to allow for :onfailure
      return 0
    end
  end

  def self.get_input
    STDIN.gets.chomp
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

end
