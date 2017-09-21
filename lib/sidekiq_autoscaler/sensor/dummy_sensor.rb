module SidekiqAutoscaler::Sensor
  class DummySensor
    include SidekiqAutoscaler
    include SidekiqAutoscaler::Util::Loggable

    @next_check = nil
    ##
    # stopped: if service is stopped(no instances)
    def check(stopped)
      @next_check ||= DateTime.now + 2.seconds

      if @next_check > DateTime.now
        log(:debug, 'Wait...')
        return Action::NOOP
      end
      @next_check = nil

      r = rand(0..3)
      return Action::DECREASE if r == 0
      return Action::NOOP if [1,2].include?(r)
      return Action::INCREASE
    end
  end #class
end #module