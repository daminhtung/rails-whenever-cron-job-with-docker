# syntax=docker/dockerfile:1
FROM ruby:3.0.2

RUN apt-get update -qq && apt-get install -y nodejs cron npm\
  && rm -rf /var/lib/apt/lists/* \
  && curl -o- -L https://yarnpkg.com/install.sh | bash

RUN mkdir /crontab_demo
WORKDIR /crontab_demo
COPY Gemfile /crontab_demo/Gemfile
COPY Gemfile.lock /crontab_demo/Gemfile.lock
COPY start.sh crontab_demo/start.sh
RUN bundle install

RUN npm install --global yarn

COPY . /crontab_demo

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD /bin/sh scripts/start.sh