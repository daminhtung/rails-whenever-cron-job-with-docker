whenever --set environment=$RAILS_ENV --update-crontab

service cron restart

bundle exec rails server --binding 0.0.0.0