#!/bin/bash

if [ -e ./resque-pool.pid ]; then
	RESQUE_PID=$(cat resque-pool.pid)
	if kill -0 $RESQUE_PID; then
		echo "Killing Pool Master at $RESQUE_PID" 
		kill -QUIT $RESQUE_PID
		while [ -e ./resque-pool.pid ]; do
			echo -n '.'
			sleep 1
		done
		echo
	else
		echo "Bad PID in ./resque-pool.pid"
	fi
fi

RAILS_ENV=dlvecnet rake assets:precompile

echo "Reloading unicorn"
./reload-unicorn.sh

echo "Restarting pool"
./start-pool.sh

