require 'spec_helper'

describe 'Dummy Sensor and Actuator integration test' do
  before(:context) do
    @logger = Logger.new(STDOUT)
  end

  it 'should initialize correctly' do
    sensor = SidekiqAutoscaler::Sensor::DummySensor.new
    actuator = SidekiqAutoscaler::Actuator::DummyActuator.new
    as = SidekiqAutoscaler::Autoscaler.new(sensor, actuator)
    as.logger = @logger

    as.start!(0)
    sleep 5
    as.stop!
  end
end
