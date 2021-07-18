#!/bin/bash
# Setup a cron schedule
# cp /app/app.cron /etc/cron.d/app.cron
# service cron start
#

# CONSIDERED CRON JOB BUT THIS IS EASIER
# MAYBE I'LL MOVE BACK TO CRON JOB LATER
TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
echo "$TIMESTAMP Starting cron worker"
while true
do
  TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
  echo "$TIMESTAMP Cron worker is running"
  ./lib/scheduled/get_recent_tweets
  sleep 15m
done
