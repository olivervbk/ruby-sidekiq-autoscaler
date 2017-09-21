module SidekiqAutoscaler::Sensor
  require 'sidekiq'

  require 'sidekiq_autoscaler/util/sidekiq_util'

  class SidekiqSensor
    include SidekiqAutoscaler
    include SidekiqAutoscaler::Util::Loggable

    # seconds that a job can stay in the queue before the number of instances should increase
    @latency_threshold = nil
    @sample_window = nil

    def initialize(options=ENV)
      @sample_window = (options[CONF_PREFIX+'SAMPLE_WINDOW'] || '2').to_i
      @latency_threshold = (options[CONF_PREFIX+'LATENCY_THRESHOLD'] || '20').to_i
    end

    @next_check = nil
    ##
    # stopped: if service is stopped(no instances)
    def check(stopped)
      @next_check ||= DateTime.now + @sample_window.seconds

      queue_size = Util::SidekiqUtil.queue_size
      scheduled_size = Util::SidekiqUtil.scheduled_size
      has_queued_items = queue_size > 0 || scheduled_size > 0

      # can have ZERO instances. If a job is queued, should add a worker immediately

      if stopped && has_queued_items
        @next_check = nil
        return Action::INCREASE
      end

      if @next_check > DateTime.now
        log(:debug, 'Wait...')
        return Action::NOOP
      end
      @next_check = nil
      log(:debug, 'Check...')

      latency = Util::SidekiqUtil.max_latency || 0
      return Action::INCREASE if latency > @latency_threshold

      return Action::STOP unless has_queued_items

      # TODO check if NOOP?
      return Action::DECREASE
    end
  end #class
end #module
