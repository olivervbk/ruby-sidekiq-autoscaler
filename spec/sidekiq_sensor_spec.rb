require 'spec_helper'
require 'sidekiq_autoscaler/sensor/sidekiq_sensor'

describe 'SidekiqSensor' do
  before(:context) do
  end


  it 'should initialize with params' do
    SidekiqAutoscaler::Sensor::SidekiqSensor.new({
      'SIDEKIQ_AUTOSCALER_APP_NAME' => 'not_empty',
      'SIDEKIQ_AUTOSCALER_HEROKU_API_KEY' => 'not_empty'
    })
  end
end

