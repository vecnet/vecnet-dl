#!/bin/bash

echo "Stopping Resque pool"

app_root=$(cd $(dirname $0)/.. && pwd)

resque_pid_file="$app_root/tmp/pids/resque-pool.pid"

if [ ! -e $resque_pid_file ]; then
    echo "Cannot find resque-pool.pid"
    exit
fi

RESQUE_PID=$(cat $resque_pid_file)
if kill -0 $RESQUE_PID; then
    echo "Killing Pool Master at $RESQUE_PID"
    kill -QUIT $RESQUE_PID
else
    echo "Process ID in $resque_pid_file does not exist"
fi

