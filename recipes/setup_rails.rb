server :local, :address => "127.0.0.1", :user => "root", :password => "none"
task :setup_rails, :local => true do
  local "mkdir -p config/screwcap"
  local "mkdir -p lib/tasks"
  local "curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/rails_tasks.rb > config/screwcap/rails_tasks.rb"
  local "curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/screwcap.rake > lib/tasks/screwcap.rake"
  local "curl -s http://github.com/gammons/screwcap_recipes/raw/master/rails/recipe.rb > config/screwcap/recipe.rb"
end
