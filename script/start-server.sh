#!/bin/bash

# Starts the server on the dl-vecnet server. It assumes
# there is an nginx reverse proxy at port 80

source /etc/profile.d/chruby.sh
chruby 2.0.0-p353

#LISTEN_PORTS="-l 127.0.0.1:3001"
source /home/app/vecnet/current/script/get-env.sh
cd $RAILS_ROOT
bundle exec unicorn -D -E deployment -c $RAILS_ROOT/config/unicorn.rb
