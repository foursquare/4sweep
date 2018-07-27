4sweep
======

4sweep is a Rails 3.2 web application for mass editing of Foursquare venues. It
is built on a concept of "flags" that can be submitted to the Foursquare API
v2. 4sweep supports the following flag types, which all operate on venues:

 * Edit Venue Details (name, address, contacts, etc)
 * Close Flag (event over, closed) and Re-Open
 * Delete Flag (inappropriate, does not exist) and Undelete
 * Make Private Flag
 * Change Categories (add, remove, replace all, with special home category flag)
 * Photo Flags
 * Tip Flags

Additionally, there is a rich Javascript based UI that makes generating hundreds
of flags feasible. The UI uses the Google Maps API v3.

Flags are submitted against the Foursquare API using a queue managed
by DelayedJob.

Current Status
--------------

4sweep was unmaintained as of March 2015, but in July of 2018, 4sweep was open sourced and has become primarily maintained by Foursquare. While Foursquare will make periodic security and maintenance updates, the 4sweep/Foursquare community is highly encouraged to fork and submit pull requests with new features.


Explorer Features
-----------------

 * Generate flags of any type quickly
 * Search based on:
   * Search term
   * Categories
   * Center point + radius
   * Bounding box
   * Mayorships of user
   * Recently created venues
 * Split large areas into smaller subareas
 * Filter venues using an advanced search BNF grammar

Flag Features
-------------
 * Flags can have comments
 * Can be checked to see if they were applied
 * Can be scheduled for a future date (through Delayed Job)

Configuration and setup
-----------------------

4sweep is currently built for Rails 3.2 (Ruby 2.0.0) and uses Bootstrap 2.0.  You will need
to install all required gems. It relies on a database supported by ActiveRecord,
and has only been tested with MySQL 5.5/5.6.

Additionally, you will need to install PEG.js, a JavaScript parser generator
library.  The easiest way to do this is via npm:

```shell
$ npm install pegjs
```
After installing PEG.js, make sure that it is executable on your command line:

```shell
$ pegjs -v
PEG.js 0.8.0
```

You only need PEG.js in your development environment. It is used as part of the
Rails asset pipeline to generate a javascript parser.


ENV Variable Storage
----

4sweep now uses ENV variables to store sensitive config variables (like api keys, database credentials, etc). Feel free to use whatever method of storing these ENV variables works best for you, but if a `config/app_environment_variables.rb` file is present, it will be loaded. An example of what that file might look like (and the variables currently stored) can be found in the `config/app_environment_variables-example.rb` file.

Most recent variables used:
```
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
```

