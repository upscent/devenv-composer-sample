FROM ruby:2.2

ENV APP_ROOT /app
WORKDIR $APP_ROOT

RUN gem install bundler
RUN bundle config --global path vendor/bundler

ADD ./replace_host.sh /.

