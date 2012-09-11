INSTANCES = 3
BASE_PORT = 3000
RACKUP = File.expand_path(File.join(File.dirname(__FILE__), "..", "config.ru"))

INSTANCES.times do |instance|
  log_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "log", "gdash.#{instance}.log"))

  God.watch do |watch|
    watch.name = "GDash #{instance}"
    watch.group = "gdash"
    watch.start = "bundle exec thin --rackup #{RACKUP} --port #{BASE_PORT + instance} --log #{log_file} start"
    watch.behavior :clean_pid_file
    watch.keepalive
    watch.log = log_file
  end
end