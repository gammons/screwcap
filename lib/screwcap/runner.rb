class Runner
  def self.execute! task
    @task = task
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
      @task.log "\n*** BEGIN executing task #{@task.__name} on #{server.name} with address #{address}\n", :color => :blue

      server.__with_connection_for(address) do |ssh|
        error = false
        @task.__commands.each do |command|
          next if error and self.__options[:stop_on_errors]

          if command[:type] == :remote
            @task.log "    I: (#{address}):  #{command[:command]}\n", :color => :green

              ssh.exec! command[:command] do |ch,stream,data|
                if stream == :stderr
                  error = true
                @task.errorlog "    E: (#{address}): #{data}", :color => :red
              else
                @task.log "    O: (#{address}):  #{data}", :color => :green
              end
            end # ssh.exec
          elsif command[:type] == :local
            ret = `#{command[:command]}`
            if $?.to_i == 0
              @task.log "    I: (local):  #{command[:command]}\n", :color => :blue
              @task.log "    O: (local):  #{ret}\n", :color => :blue
            else
              @task.log "    I: (local):  #{command[:command]}\n", :color => :blue
              @task.errorlog "    O: (local):  #{ret}\n", :color => :red
            end
          elsif command[:type] == :scp
            server.__upload_to!(address, command[:local], command[:remote])
            @task.log "    I: (#{address}): SCP #{command[:local]} to #{server.__user}@#{address}:#{command[:remote]}\n", :color => :green
          end
        end # commands.each
      end # net.ssh start
    rescue Net::SSH::AuthenticationFailed => e
      raise Net::SSH::AuthenticationFailed, "Authentication failed for server named #{server.name}.  Please check your authentication credentials."
    rescue Exception => e
      @task.errorlog "    F: (#{address}): #{e}", :color => :red
    ensure
      @task.log "*** END executing task #{@task.__name} on #{server.name} with address #{address}\n\n", :color => :blue
    end
  end

end
