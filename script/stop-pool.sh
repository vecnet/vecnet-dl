#!/bin/bash

echo "Stopping Resque pool"

app_root=$(cd $(dirname $0)/.. && pwd)

resque_pid_file="$app_root/tmp/pids/resque-pool.pid"

if [ -e $resque_pid_file ]; then
    RESQUE_PID=$(cat $resque_pid_file)
    if kill -0 $RESQUE_PID; then
        echo "Killing Pool Master at $RESQUE_PID" 
        kill -QUIT $RESQUE_PID
        while [ -e $resque_pid_file ]; do
            echo -n '.'
            sleep 1
        done
        echo
    else
        echo "Bad PID in $resque_pid_file"
    fi
else
    echo "Could not find $resque_pid_file"
fi

