require 'ruby-debug'
Debugger.start

# a *Command Set* is a generic set of runnable items that can be executed by any *Task*.
# You can tell a command set which variables to use by using the C or mysql style compiled functions:
#
# <pre>
# command_set :symlink, :depends => :svn_check_out do |c|
#   c.run "rm -f _var_/current", "deploy[:dir]"
#   c.run "ln -s _var_ _var_/current", :release_directory, "deploy[:dir]"
# end
# </pre>
#
# The command set will look for the special token <tt>_var_</tt>, and replace it with the current value given as a param.
# The first command will use the current value of <tt>deploy[:dir]</tt>, which may be defined globally or locally by the task.  
# The second command uses two variables, <tt>release_directory</tt> and also <tt>deploy[:dir]</tt>.  For variables that are non-hashes, you can use a symbol to reference the variable.  
#
# The <tt>_var_</tt> token will be replaced by the variables given in order.  
class CommandSet < Screwcap::Base
  attr_accessor :name, :commands

  # Create a new command set.  Currently no options are supported, but options will be available in future releases.
  def initialize(name, options = {})
    @name = name
    @commands = []
    @options = options.clone
  end

  # Run a command.  You can pass variables that the command will run via the special syntax described above.
  # Ex.  run "command _var_ _var_", :variable1, :variable2
  # Ex.  run "command _var_ _var_", "hash[:var1]", "hash[:var2]"
  # The variables will be dynamically replaced, in the order received, by thier value scoped to the task that is running the command set.
  def run cmd, *vars
    @commands << {:command => cmd, :vars => vars}
  end

  def compile_commands_with(options) 
    return if @commands.nil? or @commands == [] 
    commands = @commands

    commands.each do |c|
      # first attempt to use the var we passed in, for tasks
      c[:compiled_command] = c[:command].clone

      c[:vars].each do |var| 
        if var.is_a?(Symbol)
          var_value = options[var].nil? ? @options[var] : options[var]
        elsif var.is_a?(String)
          # assume this is a hash
          hash_name = var.split("[").first
          key = var.split("[").last.gsub(/\]/,'').gsub(/:/,'')
          raise ArgumentError, "Only use strings for command set variables if it is referencing a hash, like  \"apache[:dir]\".  Otherwise just use a symbol. [at: #{var}]" if hash_name.nil?
          raise ArgumentError, "Only use strings for command set variables if it is referencing a hash, like  \"apache[:dir]\".  Otherwise just use a symbol. [at: #{var}]" if key.nil?

          begin
            var_value = options[hash_name.to_sym][key.to_sym].nil? ? @options[hash_name.to_sym][key.to_sym] : options[hash_name.to_sym][key.to_sym]
          rescue NoMethodError
            $stdout << "\n\n*** Configuration Error: Could not find variable named #{hash_name}[:#{key}]. Please ensure it is defined in your task or your server spec.\n\n"
            exit
          end
        end
        c[:compiled_command].sub! /_var_/,var_value.to_s
      end
    end
    commands
  end
end

