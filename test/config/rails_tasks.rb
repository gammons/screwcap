command_set :create_directory_structure do
  run "mkdir -p #{release_dir}"
  run "mkdir -p #{deploy_dir}/shared/pids"
  run "mkdir -p #{deploy_dir}/shared/system"
  run "mkdir -p #{deploy_dir}/shared/log"
end

command_set :after_checkout do
  run "chmod -R g+w #{release_dir}"
  run "rm -rf #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/log #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/system #{deploy_dir}/system"
  run "TZ=UTC find #{release_dir}/public/images -exec touch -t #{stamp};"
  run "TZ=UTC find #{release_dir}/public/stylesheets -exec 'touch -t #{stamp};"
  run "TZ=UTC find #{release_dir}/public/javascripts -exec touch -t #{stamp};"
end

command_set :svn_check_out do
  create_directory_structure
  run "svn co #{svn_url} --username=#{svn_user} --password=#{svn_password} -q #{release_dir}"
  after_checkout
end

command_set :git_check_out do
  create_directory_structure
  run "git clone --depth 10 git@#{git_url}:#{git_project} #{release_dir}"
  after_checkout
end

command_set :symlink do
  run "rm -f #{deploy_dir}/current", "deploy[:dir]"
  run "ln -s #{release_dir} #{deploy_dir}/current"
end

command_set :restart_mongrels do
  run "for file in #{mongrel_pid_dir}/*.pid; do mongrel_rails stop -P ${file} 2&>1; sleep 5;  done"
end
