FROM ruby:2.5.3-alpine
ENV LANG C.UTF-8

RUN apk update && apk add --no-cache \
  openssh \
  git \
  tzdata \
  libxml2-dev \
  curl-dev \
  make \
  gcc \
  libc-dev \
  g++ \
  nodejs \
  nodejs-npm \
  mysql-dev \
  mysql-client \
  ruby-nokogiri


RUN gem install bundler

ENV BUNDLER_VERSION 2.0.2
RUN gem install bundler --version $BUNDLER_VERSION

ENV APP_HOME /app
RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* ./
RUN bundle install --jobs=4 --without production --path vendor/bundle

ADD . $APP_HOME
