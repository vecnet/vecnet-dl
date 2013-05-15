#!/bin/bash

RAILS_ENV=dlvecnet bundle exec resque-pool --daemon \
 --pidfile resque-pool.pid \
 --stdout log/resque-pool.stdout.log \
 --stderr log/resque-pool.stderr.log \
 --environment dlvecnet
