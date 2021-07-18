#!/bin/bash

echo "Worker booting up"

set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-5} -r ./bootup.rb