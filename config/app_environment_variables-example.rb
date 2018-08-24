# Use this file to load ENV variables in development mode:
# https://stackoverflow.com/questions/4911607/is-it-possible-to-set-env-variables-for-rails-development-environment-in-my-code/11765775#11765775
ENV['APP_SECRET'] = 'REPLACE_ME'

ENV['DB_ADAPTER'] = 'mysql2'
ENV['DB_DATABASE'] = 'REPLACE_ME'
ENV['DB_USERNAME'] = 'REPLACE_ME'
ENV['DB_PASSWORD'] = 'REPLACE_ME'
ENV['DB_HOST'] = 'localhost'

ENV['FOURSQUARE_CLIENT_ID'] = 'REPLACE_ME'
ENV['FOURSQUARE_CLIENT_SECRET'] = 'REPLACE_ME'
ENV['OAUTH_CALLBACK'] = 'http://localhost:3000/session/callback'
ENV['GOOGLE_MAPS_KEY'] = 'REPLACE_ME'
ENV['AWS_KEY'] = 'REPLACE_ME'
ENV['AWS_SECRET'] = 'REPLACE_ME'
ENV['AWS_S3_BUCKET'] = 'REPLACE_ME'
ENV['CLOUDWATCH_KEY'] = 'REPLACE_ME'
ENV['CLOUDWATCH_SECRET'] = 'REPLACE_ME'
ENV['ROLLBAR_ACCESS_TOKEN'] = 'REPLACE_ME'
