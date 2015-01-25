#!/bin/bash

app_root=$(cd $(dirname $0)/.. && pwd)

# Try to get a lock, and exit if someone else already has it.
# This keeps a lot of harvest processes from spawning
# should a paricular harvest take a long time.
# The lock is released when this shell exits.
exec 200> "$app_root/tmp/harvest-nginx"
flock -e --nonblock 200 || exit 0

cd $app_root
if [ -e /etc/profile.d/chruby.sh ]; then
    source /etc/profile.d/chruby.sh
    chruby 2.0.0-p353
    source $app_root/script/get-env.sh
fi

# TODO: figure out which file is the new one
export HARVEST_DIR=/var/log/nginx
export HARVEST_STATE=/opt/vecnet-dl/shared/tmp/nginx-ingested

bundle exec rake vecnet:usage:sync_fedora
