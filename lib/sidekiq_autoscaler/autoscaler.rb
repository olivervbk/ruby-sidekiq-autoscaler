module SidekiqAutoscaler
  class Autoscaler
    include SidekiqAutoscaler
    include SidekiqAutoscaler::Util::Loggable

    @scale_sensor = nil
    @scale_actuator = nil

    @thread = nil

    def initialize(sensor = Sensor::DummySensor.new, scale_actuator = Actuator::DummyActuator.new, options = ENV)
      self.log_prefix='SIDEKIQ_AUTOSCALER: '

      @scale_sensor = sensor
      @scale_actuator = scale_actuator
    end

    #HACK
    def logger=(logger)
      @scale_sensor.logger=logger
      @scale_actuator.logger=logger
      @logger = logger
    end

    public ########################################### PUBLIC ##########################################################

    def start!(boot_delay = 0)
      raise 'Already running.' unless @thread.nil?
      @thread = Thread.new {
        sleep boot_delay
        log('booted autoscaler')

        loop {
          break if Thread.current[:stop]
          sleep 5

          begin
            scale!
          rescue => e
            log(:error, "Error scaling: #{e.message}\n#{e.backtrace}")
          end
        }
      }
    end

    def stop!
      raise 'Not running.' if @thread.nil?
      @thread[:stop] = true
      @thread = nil
    end

    def scale!
      unless @scale_actuator.try(:active?)
        log(:warn, "Actuator:#{@scale_actuator.class} is not active! Check your logs.")
        return
      end

      is_stopped = @scale_actuator.stopped?
      action = @scale_sensor.check(is_stopped)
      if action == Action::INCREASE
        @scale_actuator.increase
      elsif action == Action::DECREASE
        @scale_actuator.decrease
      elsif action == Action::STOP
        @scale_actuator.decrease(true)
      end
    end

    private ################################################## PRIVATE #################################################

  end #class
end
