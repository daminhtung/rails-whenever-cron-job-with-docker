set :output, "log/cron_log.log"
ENV.each { |k, v| env(k, v) }

every 2.minutes do
    runner "puts 'HELLO FROM LOGGER'"
end