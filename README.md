# ruby-sidekiq-autoscaler
Modular autoscaler focused on sidekiq+heroku applications

A simple modular autoscaler, not tied to a specific configuration and can be run inline or in separate thread.
The idea is to have a sensor, which reports if it should scale up,down,stop or stay at the value; 
and to have a actuator, which acts on the reports.

The current focus of the autoscaler is to use the sidekiq metrics of queue latency to adjust the number of workers. 
The oldest queued job defines if the workers should be scaled up. It can also be used to shutdown all workers, 
though in this mode it will sping up a worker as soon as a job is queued or scheduled.

The HerokuWorkerActuator tries to quiet the SidekiqWorkers before shutting them down, or rebooting them if the queue grows again.
Needs to be tested more.

# Getting started
## Install
Add to **Gemfile**:

`gem 'sidekiq_autoscaler', '0.1.0', git: 'https://github.com/olivervbk/ruby-sidekiq-autoscaler.git'`

and run

`bundle install`

## Configure
The expected way to run this is on your webserver (Rails?), running on the dyno 'web.1', so that only one server runs the autoscaler.

**config/initializers/sidekiq_autoscaler.rb**:

```
require 'logger'
require 'sidekiq_autoscaler'
require 'sidekiq_autoscaler/sensor/sidekiq_sensor'
require 'sidekiq_autoscaler/actuator/heroku_worker_actuator'

manager_dyno = ENV['SIDEKIQ_AUTOSCALER_DYNO'] || 'web.1'
current_dyno = ENV['DYNO']
is_production = Rails.env.production?
if is_production && current_dyno == manager_dyno
  sensor = SidekiqAutoscaler::Sensor::SidekiqSensor.new
  actuator = SidekiqAutoscaler::Actuator::HerokuWorkerActuator.new
  autoscale = SidekiqAutoscaler::Autoscaler.new(sensor,actuator)
  autoscale.start!
end
```

### Environment variables:
* Sensor::SidekiqSensor
  * SIDEKIQ_AUTOSCALER_SAMPLE_WINDOW - seconds in which Sensor::SidekiqSensor tries to read the state
  * SIDEKIQ_AUTOSCALER_LATENCY_THRESHOLD - threshold that a job can stay queued before it tries to increase the scaling
* Actuator:HerokuWorkerActuator
  * SIDEKIQ_AUTOSCALER_MIN - minimum scaled workers
  * SIDEKIQ_AUTOSCALER_MAX - maximum scaled workers
  * SIDEKIQ_AUTOSCALER_APP_NAME - name of your heroku app that will be managed
  * SIDEKIQ_AUTOSCALER_HEROKU_API_KEY - key to manage the app
  
# TODO
1. add fast queue growth heuristics. Currently, it only scales if the jobs have been queued a while, which slows the scaling response.
2. test in production
3. add a web interface to adjust values on the fly, saving to Redis?
4. improve scaling algorithm so that it doesn't always try to use the minimum number of nodes
5. check if the scheduled jobs on sidekiq will happen soonish before spinning up a worker because of them.

## Contributing
Sure, just send me a pull request with the changes :)
Feedback appreciated.
