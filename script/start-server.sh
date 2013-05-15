#!/bin/bash

# Starts the server on the dl-vecnet server. It assumes
# there is an nginx reverse proxy at port 80

source /etc/profile.d/chruby.sh
chruby 1.9.3-p392

#LISTEN_PORTS="-l 127.0.0.1:3001"
export RAILS_ROOT=/home/app/vecnet/current

RAILS_ENV=qa bundle exec unicorn -D -E deployment -c $RAILS_ROOT/config/unicorn.rb
