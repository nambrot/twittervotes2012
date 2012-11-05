worker_processes 3 # amount of unicorn workers to spin up
timeout 10000

@resque_pid = nil
@resque_pid2 = nil
@resque_pid3 = nil

before_fork do |server, worker|
  @resque_pid ||= spawn("bundle exec rake jobs:work")
  @resque_pid2 ||= spawn("bundle exec rake jobs:work")
  
end
