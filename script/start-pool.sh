#!/bin/bash

chruby 1.9.3-p392
RAILS_ENV=dlvecnet bundle exec resque-pool --daemon \
 --pidfile tmp/pids/resque-pool.pid \
 --stdout log/resque-pool.stdout.log \
 --stderr log/resque-pool.stderr.log \
 --environment dlvecnet
