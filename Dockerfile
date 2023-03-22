FROM ruby:2.7-buster

ARG artifactory_creds

# Install core components and some dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential lsb-release libxml2-dev libxslt1-dev

# Install nodejs & npm with nvm; use npm to install peggy
ENV NODE_VERSION=18.15.0 NVM_DIR=/root/.nvm

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm use v${NODE_VERSION} && \
    nvm alias default v${NODE_VERSION} && \
    npm install -g peggy

# Install bundler and ruby project from Gemfile; set up the app environment
ENV APP_HOME=/4sweep DB_ADAPTER=mysql2 RAILS_SERVE_STATIC_FILES=true 
COPY . $APP_HOME/
WORKDIR $APP_HOME

RUN . $NVM_DIR/nvm.sh && \
    gem update --system 3.1.1 && \
    gem install bundler:2.4.3 && \
    BUNDLE_FOURSQUAREDEV__JFROG__IO=$artifactory_creds bundle install

CMD ./entrypoint.sh
