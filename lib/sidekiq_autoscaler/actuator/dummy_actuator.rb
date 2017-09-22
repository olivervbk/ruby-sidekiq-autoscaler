module SidekiqAutoscaler::Actuator
  class DummyActuator
    include SidekiqAutoscaler
    include SidekiqAutoscaler::Util::Loggable

    @min_instances = nil
    @max_instances = nil

    @instances = nil
    def initialize(options=ENV)
      self.log_prefix='DUMMY_ACTUATOR: '

      @min_instances = (options[SidekiqAutoscaler::CONF_PREFIX+'MIN'] || '1').to_i
      @max_instances = (options[SidekiqAutoscaler::CONF_PREFIX+'MAX'] || '1').to_i
      @instances = 0
    end

    def active?
      true
    end

    def stopped?
      @instances == 0
    end

    def increase
      if @instances >= @max_instances
        log('INCREASE: limit reached')
        return false
      end
      @instances += 1
      log("ADDED one worker(#{@instances})")
      return true
    end

    def decrease(stop=false)
      if @instances > [1, @min_instances].max
        @instances -= 1
        log("REMOVING one worker(#{@instances})")
        return true
      end

      if @instances > [0, @min_instances].max && stop
        @instances -= 1
        log("STOPPING one worker(#{@instances})")
        return true
      end

      log('DECREASE: limit reached')
      return false
    end
  end #class
end #module