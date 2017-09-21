module SidekiqAutoscaler
  require 'date'

  module Action
    INCREASE = 1
    DECREASE = -1
    STOP = -2
    NOOP = 0
  end

  CONF_PREFIX = 'SIDEKIQ_AUTOSCALER_'
  VERSION = '0.1'
  require 'sidekiq_autoscaler/util'
  require 'sidekiq_autoscaler/util/loggable'

  require 'sidekiq_autoscaler/sensor'
  require 'sidekiq_autoscaler/sensor/dummy_sensor'

  require 'sidekiq_autoscaler/actuator'
  require 'sidekiq_autoscaler/actuator/dummy_actuator'

  require 'sidekiq_autoscaler/autoscaler'

end
