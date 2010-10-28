server :local, :address => "127.0.0.1", :user => "root", :password => "none"
task :setup_rails, :local => true do
  local "mkdir -p config/screwcap"
  local "mkdir -p lib/tasks"

  local <<-EOF
    if [ -f config/screwcap/rails_tasks.rb ]
    then
      echo "config/screwcap/rails_tasks.rb already exists!"; exit 1
    else
      curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/rails_tasks.rb > config/screwcap/rails_tasks.rb
    fi
  EOF

  local <<-EOF
    if [ -f lib/tasks/screwcap.rake ]
    then
      echo "lib/tasks/screwcap.rake already exists!"; exit 1
    else
      curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/screwcap.rake > lib/tasks/screwcap.rake
    fi
  EOF
   
  local <<-EOF
    if [ -f config/screwcap/recipe.rb ]
    then
      echo "config/screwcap/recipe.rb already exists!"; exit 1
    else
      curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/recipe.rb > config/screwcap/recipe.rb
    fi
  EOF
end
