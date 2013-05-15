#
# copied from https://gist.github.com/2129714
#

rails_root = ENV["RAILS_ROOT"]
working_directory rails_root
worker_processes 2
listen "/tmp/unicorn.sock.0", backlog: 1024
listen "/tmp/unicorn.sock.1", backlog: 1024
timeout 30

pid "#{rails_root}/tmp/pids/unicorn.pid"

stderr_path "#{rails_root}/log/unicorn.stderr.log"
stdout_path "#{rails_root}/log/unicorn.stdout.log"

Configurator::DEFAULTS[:logger].formatter = Logger::Formatter.new

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

# TODO: add in redis reconnection.

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
