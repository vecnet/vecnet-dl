# List all tasks from RAILS_ROOT using: cap -T
#
# NOTE: The SCM command expects to be at the same path on both the local and
# remote machines. The default git path is: '/shared/git/bin/git'.

set :bundle_roles, [:app]
set :bundle_flags, "--deployment"
require 'bundler/capistrano'
# see http://gembundler.com/v1.3/deploying.html
# copied from https://github.com/carlhuda/bundler/blob/master/lib/bundler/deployment.rb
#
# Install the current Bundler environment. By default, gems will be \
#  installed to the shared/bundle path. Gems in the development and \
#  test group will not be installed. The install command is executed \
#  with the --deployment and --quiet flags. If the bundle cmd cannot \
#  be found then you can override the bundle_cmd variable to specifiy \
#  which one it should use. The base path to the app is fetched from \
#  the :latest_release variable. Set it for custom deploy layouts.
#
#  You can override any of these defaults by setting the variables shown below.
#
#  N.B. bundle_roles must be defined before you require 'bundler/#{context_name}' \
#  in your deploy.rb file.
#
#    set :bundle_gemfile,  "Gemfile"
#    set :bundle_dir,      File.join(fetch(:shared_path), 'bundle')
#    set :bundle_flags,    "--deployment --quiet"
#    set :bundle_without,  [:development, :test]
#    set :bundle_cmd,      "bundle" # e.g. "/opt/ruby/bin/bundle"
#    set :bundle_roles,    #{role_default} # e.g. [:app, :batch]

#############################################################
#  Settings
#############################################################

default_run_options[:pty] = true
set :use_sudo, false
ssh_options[:paranoid] = false
set :default_shell, '/bin/bash'

#############################################################
#  SCM
#############################################################

set :scm, :git
set :deploy_via, :remote_cache
set :scm_command, '/usr/bin/git'

#############################################################
#  Environment
#############################################################

namespace :env do
  desc "Set command paths"
  task :set_paths do
    set :ruby,      File.join(ruby_bin, 'ruby')
    #set :bundler,   File.join(ruby_bin, 'bundle')
    #set :bundler,   'bundle'
    set :rake,      "#{bundle_cmd} exec rake"
  end
end

# we are using chruby on the deploment machine
# code from https://github.com/postmodern/chruby/wiki/Capistrano
set :ruby_version, "1.9.3-p392"
set :chruby_config, "/etc/profile.d/chruby.sh"
set :set_ruby_cmd, "source #{chruby_config} && chruby #{ruby_version}"
set(:bundle_cmd) {
  "#{set_ruby_cmd} && exec bundle"
}

#############################################################
#  Passenger
#############################################################

desc "Restart Application"
task :restart_unicorn do
  run "#{current_path}/script/reload-unicorn.sh"
end

#############################################################
#  Database
#############################################################

namespace :db do
  desc "Run the seed rake task."
  task :seed, :roles => :app do
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} db:seed"
  end
end

#############################################################
#  Deploy
#############################################################

namespace :deploy do
  desc "Execute various commands on the remote environment"
  task :debug, :roles => :app do
    run "/usr/bin/env", :pty => false, :shell => '/bin/bash'
    run "whoami"
    run "pwd"
    run "echo $PATH"
    run "which ruby"
    run "ruby --version"
    run "which rake"
    run "rake --version"
    run "which bundle"
    run "bundle --version"
  end

  desc "Start application"
  task :start, :roles => :app do
    restart_unicorn
  end

  desc "Restart application"
  task :restart, :roles => :app do
    restart_unicorn
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Run the migrate rake task."
  task :migrate, :roles => :app do
    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} db:migrate"
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    symlink_targets.each do | source, destination, shared_directory_to_create |
      run "mkdir -p #{File.join( shared_path, shared_directory_to_create)}"
      run "ln -nfs #{File.join( shared_path, source)} #{File.join( release_path, destination)}"
    end
  end

  desc "Precompile assets"
  task :precompile do
    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} RAILS_GROUPS=assets assets:precompile"
  end

  desc "Setup application symlinks for shared assets"
  task :symlink_setup, :roles => [:app, :web] do
    shared_directories.each { |link| run "mkdir -p #{shared_path}/#{link}" }
  end

  desc "Link assets for current deploy to the shared location"
  task :symlink_update, :roles => [:app, :web] do
    (shared_directories + shared_files).each do |link|
      run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
    end
  end
end

# this code doesn't work quite right, but it is the way to do it.
# from http://stackoverflow.com/questions/4648180/keep-unversioned-files-when-deploying-with-capistrano
# TODO: fix
#before "deploy:setup" do
#  symlinks.setup
#end
#
#before "deploy:symlink" do
#  symlinks.update
#end

#namespace :worker do
#  task :start, :roles => :work do
#    target_file = "/home/Vecnet/resque-pool-info"
#    run [
#      "echo \"RESQUE_POOL_ROOT=$(pwd)/current\" > #{target_file}",
#      "echo \"RESQUE_POOL_ENV=#{fetch(:rails_env)}\" >> #{target_file}",
#      "sudo /sbin/service resque-poold restart"
#    ].join(" && ")
#  end
#end

namespace :vecnet do
  desc "Restart the workers on the target machine"
  task :restart_workers, :roles => :work do
    run [
      "#{current_path}/script/stop-pool.sh",
      "#{current_path}/script/start-pool.sh"
    ].join(" && ")
  end
end

namespace :und do
  task :update_secrets do
    #run "cd #{release_path} && ./script/update_secrets.sh #{secret_repo_name}"
  end

  task :write_build_identifier, :roles => :app do
    run "cd #{release_path} && echo '#{build_identifier}' > config/bundle-identifier.txt"
  end
end

#############################################################
#  Callbacks
#############################################################

before 'deploy', 'env:set_paths'

#############################################################
#  Configuration
#############################################################

set :application, 'vecnet-dl'
set :repository,  "git://github.com/banurekha/vecnet.git"

set :build_identifier, Time.now.strftime("%Y-%m-%d %H:%M:%S")

#############################################################
#  Environments
#############################################################

desc "Setup for the QA environment"
task :qa do
  set :shared_directories, %w(log)
  set :shared_files, %w(config/database.yml config/fedora.yml config/solr.yml config/redis.yml )
  set :symlink_targets do
    [
      #['/bundle/config','/.bundle/config', '/.bundle'],
      ['/log','/log','/log'],
      #['/vendor/bundle','/vendor/bundle','/vendor'],
    ]
  end
  set :branch,      'master'
  set :rails_env,   'qa'
  set :deploy_to,   '/home/app/vecnet'
  set :ruby_bin,    '/opt/rubies/1.9.3-p392/bin'

  set :user,        'app'
  set :domain,      'dl-vecnet-qa.crc.nd.edu'
  set :without_bundle_environments, 'headless development test'

  default_environment['PATH'] = "#{ruby_bin}:$PATH"
  server "#{user}@#{domain}", :app, :web, :work, :db, :primary => true

  after 'deploy:update_code', 'und:write_build_identifier', 'und:update_secrets', 'deploy:symlink_shared', 'deploy:symlink_update', 'deploy:migrate', 'deploy:precompile'
  after 'deploy', 'deploy:cleanup'
  after 'deploy', 'deploy:restart'
  after 'deploy', 'vecnet:restart_workers'
end

desc "Setup for the Production environment"
task :production_cluster do
  set :symlink_targets do
    [
      #['/bundle/config','/.bundle/config', '/.bundle'],
      ['/log','/log','/log'],
      #['/vendor/bundle','/vendor/bundle','/vendor'],
      #["/config/role_map_#{rails_env}.yml","/config/role_map_#{rails_env}.yml",'/config'],
    ]
  end
  set :branch,      'release'
  set :rails_env,   'production'
  set :deploy_to,   '/shared/ruby_prod/data/app_home/curate'
  set :ruby_bin,    '/shared/ruby_prod/ruby/1.9.3/bin'

  set :user,        'rbprod'
  set :domain,      'curateprod.library.nd.edu'
  set :without_bundle_environments, 'headless development test'

  default_environment['PATH'] = "#{ruby_bin}:$PATH"
  server "#{user}@#{domain}", :app, :web, :db, :primary => true

  after 'deploy:update_code', 'und:write_build_identifier', 'und:update_secrets', 'deploy:symlink_shared', 'deploy:migrate', 'deploy:precompile'
  after 'deploy', 'deploy:cleanup'
  after 'deploy', 'deploy:restart'
end


# Trying to keep the worker environments as similar as possible
def common_worker_things
  set :symlink_targets do
    [
      #[ '/bundle/config', '/.bundle/config', '/bundle'],
      [ '/log', '/log', '/log'],
      #[ '/vendor/bundle', '/vendor/bundle', '/vendor/bundle'],
    ]
  end
  set :deploy_to,   '/home/Vecnet'
  set :ruby_bin,    '/usr/local/ruby/bin'
  set :without_bundle_environments, 'development test'
  set :group_writable, false

  default_environment['PATH'] = "#{ruby_bin}:$PATH"
  server "#{user}@#{domain}", :work
  after 'deploy', 'worker:start'
  after 'deploy:update_code', 'und:update_secrets', 'deploy:symlink_shared'
end

desc "Setup for the Preproduction Worker environment"
task :pre_production_worker do
  set :rails_env,   'pre_production'
  set :user,        'Vecnet'
  set :domain,      'curatepprdw1.library.nd.edu'
  set :branch, "master"
  common_worker_things
end

desc "Setup for the Production Worker environment"
task :production_worker do
  set :rails_env,   'production'
  set :user,        'Vecnet'
  set :domain,      'curateprodw1.library.nd.edu'
  set :branch,      'release'
  common_worker_things
end

