#!/bin/bash

. $NVM_DIR/nvm.sh

# Clear the previous server instance
if [ -f tmp/pids/server.pid ]; then
    rm tmp/pids/server.pid
fi

# Set up database
rake db:create db:migrate

# Pre-compile assets
bundle exec rake RAILS_ENV=$rails_env SECRET_KEY_BASE=asset-compilation assets:precompile

# Run
bundle exec rails server -b 0.0.0.0 -p 3000
