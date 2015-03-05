#!/bin/bash

app_root=$(cd $(dirname $0)/.. && pwd)

source /etc/profile.d/chruby.sh
chruby 2.0.0-p353

echo "Starting Resque pool"

source $app_root/script/get-env.sh
cd $RAILS_ROOT
bundle exec resque-pool --daemon \
 --pidfile $RAILS_ROOT/tmp/pids/resque-pool.pid \
 --stdout $RAILS_ROOT/log/resque-pool.stdout.log \
 --stderr $RAILS_ROOT/log/resque-pool.stderr.log \
 --environment $RAILS_ENV
