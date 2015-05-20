#!/bin/bash

app_root=$(cd $(dirname $0)/.. && pwd)
resque_pid_file="$app_root/tmp/pids/resque-pool.pid"

if [ -e $resque_pid_file ]; then
    RESQUE_PID=$(cat $resque_pid_file)

    # does process exist?
    if kill -0 $RESQUE_PID; then
        echo "Killing old pool at $RESQUE_PID"
        kill -QUIT $RESQUE_PID
    fi
fi

echo "Starting worker pool"
$app_root/script/start-pool.sh

