#!/bin/bash

if [ ! -e unicorn.pid ]; then
	exit "Cannot find unicorn.pid"
fi

PID=$(cat unicorn.pid)

# does process exist?
if kill -0 $PID; then
	echo "Stopping server at $PID"
	kill -QUIT $PID
else
	echo "Process ID in unicorn.pid does not exist"
fi

