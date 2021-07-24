FROM ruby:2.7.1

# Update the package lists before installing.
RUN apt-get update -qq
RUN apt-get install -y apt-utils libidn11-dev build-essential 

# This installs
# * build-essential because Nokogiri requires gcc
# * common CA certs
# * netcat to test the database port
RUN apt-get install -y \
    build-essential \
    ca-certificates \
    rsyslog \
    cron

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs


ENV APP_HOME /app

WORKDIR ${APP_HOME}

# Copy the Gemfile
COPY Gemfile Gemfile.lock package.json package-lock.json ${APP_HOME}/


RUN gem install bundler -v 2.2.7
RUN bundle config set --local path 'vendor/cache'


RUN bundle install
RUN npm install

COPY . ${APP_HOME}
RUN npm run build
EXPOSE 9292
