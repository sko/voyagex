#PIDFILE=./tmp/pids/resque-scheduler.pid BACKGROUND=yes rake resque:schedulerrequire 'resque/tasks'
require 'resque/scheduler/tasks'

task "resque:setup" => :environment
task "resque:scheduler_setup" => :environment

task "jobs:work" => "resque:scheduler"
