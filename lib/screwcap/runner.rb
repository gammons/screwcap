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
        error = false
        @task.__commands.each do |command|
          next if error and self.__options[:stop_on_errors]

          if command[:type] == :remote
            log "    I: (#{address}):  #{command[:command]}\n", :color => :green

              ssh.exec! command[:command] do |ch,stream,data|
                if stream == :stderr
                  error = true
                errorlog "    E: (#{address}): #{data}", :color => :red
              else
                log "    O: (#{address}):  #{data}", :color => :green
              end
            end # ssh.exec
          elsif command[:type] == :local
            ret = `#{command[:command]}`
            if $?.to_i == 0
              log "    I: (local):  #{command[:command]}\n", :color => :blue
              log "    O: (local):  #{ret}\n", :color => :blue
            else
              log "    I: (local):  #{command[:command]}\n", :color => :blue
              errorlog "    O: (local):  #{ret}\n", :color => :red
            end
          elsif command[:type] == :scp
            server.__upload_to!(address, command[:local], command[:remote])
            log "    I: (#{address}): SCP #{command[:local]} to #{server.__user}@#{address}:#{command[:remote]}\n", :color => :green
          end
        end # commands.each
      end # net.ssh start
    rescue Net::SSH::AuthenticationFailed => e
      raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
    rescue Exception => e
      errorlog "    F: (#{address}): #{e}", :color => :red
    ensure
      log "*** END executing task #{@task.__name} on #{server.name} with address #{address}\n\n", :color => :blue
    end
  end

end
