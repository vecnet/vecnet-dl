#!/bin/bash

source /etc/profile.d/chruby.sh
chruby 1.9.3-p392

RAILS_ROOT=/home/app/vecnet/current

RAILS_ENV=qa bundle exec resque-pool --daemon \
 --pidfile $RAILS_ROOT/tmp/pids/resque-pool.pid \
 --stdout $RAILS_ROOT/log/resque-pool.stdout.log \
 --stderr $RAILS_ROOT/log/resque-pool.stderr.log \
 --environment qa
