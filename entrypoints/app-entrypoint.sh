#!/bin/bash
npm run build
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rackup --host 0.0.0.0 -p 9292