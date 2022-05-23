# Perform whenever cron jobs with Docker tutorial.

1. Create rails project:
 - `rails new crontab_demo`

2. Add Dockerfile(Ref: https://docs.docker.com/samples/rails):

- File: `./Dockerfile`

```
# syntax=docker/dockerfile:1
FROM ruby:3.0.2

RUN apt-get update -qq && apt-get install -y nodejs cron npm\
  && rm -rf /var/lib/apt/lists/* \
  && curl -o- -L https://yarnpkg.com/install.sh | bash

RUN mkdir /crontab_demo
WORKDIR /crontab_demo
COPY Gemfile /crontab_demo/Gemfile
COPY Gemfile.lock /crontab_demo/Gemfile.lock
RUN bundle install

RUN npm install --global yarn

COPY . /crontab_demo

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]
```

- File: `./entrypoint.sh`

```
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /crontab_demo/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```

3. Add docker-compose.yml file:

- File: `docker-compose.yml`:

```
version: "3.9"
services:
  app:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    volumes:
      - .:/crontab_demo
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
    ports:
      - "3000:3000"
```

**Note**:

This code to sync the date time of local host machine with the app service.

```
- "/etc/timezone:/etc/timezone:ro"
- "/etc/localtime:/etc/localtime:ro"
```

4. Make sure project worked with Docker:

- `docker-compose build`

- `docker-compose up`

- Access http://localhost:3000 -> it should show the welcome screen.

5. Add whenever Gem:

- `gem 'whenever', require: false`

- `docker-compose build`

- `docker-compose run -e RAILS_ENV=development --rm app bundle`

6. Setup whenever:

- Create new file: `config/schedule.rb`:

```
set :output, "log/cron_log.log"
ENV.each { |k, v| env(k, v) }

every 2.minutes do
    runner "puts 'HELLO FROM LOGGER'"
end
```
- Create `./start.sh`:

```
whenever --set environment=$RAILS_ENV --update-crontab

service cron restart

bundle exec rails server --binding 0.0.0.0
```

- Update Dockerfile

```
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
```

- Update docker-compose.yml:

```
version: "3.9"
services:
  app:
    build: .
    command: [/bin/sh, start.sh]
    volumes:
      - .:/crontab_demo
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
    ports:
      - "3000:3000"
```

- RUN `docker-compose build` and `docker-compose up`

**Note:**   `config.webpacker.check_yarn_integrity = false`